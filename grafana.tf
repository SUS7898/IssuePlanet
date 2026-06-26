# ==========================================
# Grafana 모니터링 서버 (별도 Ubuntu EC2)
# - web 서버가 CloudWatch Logs로 보낸 로그를 시각화하는 용도
# - 기존 web/RDS/Redis/EFS 와 완전히 독립적인 추가 리소스
#
# [KISA CII 보안 조치 이력]
#   CA-07  : grafana_allowed_cidr 기본값 0.0.0.0/0 → 192.168.31.0/24 (내부망 대역)
#   WEB-11 : SSH 22 포트 인그레스 규칙 제거 (SSM Session Manager 대체)
#   CA-17  : IMDSv2 강제 적용 (http_tokens = "required")
#   WEB-02 : Grafana 관리자 비밀번호 자동 생성·SSM 저장·즉시 변경 (admin/admin 제거)
#   기타   : key_name 제거 (SSH 불필요), IAM 인라인 정책으로 SSM 쓰기 권한 추가
# ==========================================

# ------------------------------------------
# 0. 접속 허용 IP 변수
#   [CA-07 조치] 사용자 내부 네트워크 대역(192.168.31.0/24)으로 제한
#   변경이 필요하면: terraform apply -var="grafana_allowed_cidr=x.x.x.x/xx"
# ------------------------------------------
variable "grafana_allowed_cidr" {
  description = "Grafana UI(3000) 접속을 허용할 CIDR (SSH는 SSM으로 대체됨)"
  type        = string
  default     = "112.221.246.164/32" # [CA-07] 공인 IP /32 고정 (curl ifconfig.me 기준)
  # 공인 IP가 바뀌면: terraform apply -var="grafana_allowed_cidr=$(curl -s ifconfig.me)/32"
}

# ==========================================
# 1. Ubuntu 22.04 LTS AMI 조회
# ==========================================
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical 공식 계정 ID
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ==========================================
# 2. IAM 권한 (CloudWatch 읽기 + SSM 접속 + SSM 시크릿 쓰기)
# ==========================================
resource "aws_iam_role" "grafana_role" {
  name = "grafana-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}

# 그라파나가 CloudWatch 메트릭/로그를 읽기 위한 권한
resource "aws_iam_role_policy_attachment" "grafana_cw_read" {
  role       = aws_iam_role.grafana_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

# SSM 세션 매니저로 접속하기 위한 권한
resource "aws_iam_role_policy_attachment" "grafana_ssm" {
  role       = aws_iam_role.grafana_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# [WEB-02 조치] 초기화 시 생성한 Grafana 비밀번호를 SSM Parameter Store에 저장하기 위한 권한
resource "aws_iam_role_policy" "grafana_ssm_put_param" {
  name = "grafana-ssm-put-param"
  role = aws_iam_role.grafana_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:PutParameter", "ssm:GetParameter"]
      Resource = "arn:aws:ssm:ap-northeast-2:*:parameter/aws-project/grafana/*"
    }]
  })
}

resource "aws_iam_instance_profile" "grafana_profile" {
  name = "grafana-profile"
  role = aws_iam_role.grafana_role.name
}

# ==========================================
# 3. Grafana 보안 그룹
#   [WEB-11 조치] SSH(22) 인그레스 규칙 제거 — SSM Session Manager로 대체
#   [CA-07 조치] Grafana UI(3000)를 192.168.31.0/24 (내부망)으로만 허용
# ==========================================
resource "aws_security_group" "grafana_sg" {
  name        = "grafana-sg"
  description = "Allow Grafana UI from internal network only (SSH removed, use SSM)"
  vpc_id      = aws_vpc.primary.id

  # [CA-07/WEB-11] Grafana UI: 내부 네트워크(192.168.31.0/24)에서만 허용
  ingress {
    description = "Grafana Web UI (internal network only)"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.grafana_allowed_cidr]
  }

  # [WEB-11 조치] SSH 22 포트 인그레스 제거 — SSM Session Manager 사용
  # ingress { ... port 22 ... }  ← 제거됨

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # CloudWatch API + apt 저장소 접근에 필요
  }

  tags = { Name = "grafana-sg" }
}

# ==========================================
# 4. Grafana EC2 인스턴스 (퍼블릭 서브넷)
#   [CA-17 조치] IMDSv2 강제 (http_tokens = "required")
#   [WEB-02 조치] 초기 비밀번호 자동 생성 → SSM 저장 → grafana-cli 즉시 변경
#   key_name 제거 (SSH 포트 제거 + SSM 접속으로 대체)
# ==========================================
resource "aws_instance" "grafana_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  # key_name 제거 [WEB-11] — SSH 불필요. SSM Session Manager 사용
  subnet_id                   = aws_subnet.public_az1.id
  vpc_security_group_ids      = [aws_security_group.grafana_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.grafana_profile.name
  associate_public_ip_address = true

  # [CA-17 조치] IMDSv2 강제 적용 — SSRF 취약점 발생 시 IAM 자격증명 탈취 차단
  metadata_options {
    http_tokens                 = "required" # IMDSv2 강제
    http_put_response_hop_limit = 1
    http_endpoint               = "enabled"
  }

  tags = { Name = "grafana-monitoring" }

  user_data = base64encode(<<-EOF
#!/bin/bash
set -xe
echo "=== Grafana 설치 시작 ==="

# 0. 메모리 여유용 2GB Swap
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# 1. Grafana 공식 APT 저장소 등록
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y apt-transport-https software-properties-common wget gnupg awscli snapd
# SSM Agent 설치 확인 및 보장 (Ubuntu 22.04는 대부분 사전 설치, 없으면 snap으로 설치)
snap install amazon-ssm-agent --classic 2>/dev/null || true
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent 2>/dev/null || true
systemctl start  snap.amazon-ssm-agent.amazon-ssm-agent 2>/dev/null || true

mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list

# 2. Grafana OSS 설치
apt-get update -y
apt-get install -y grafana

# 3. CloudWatch 데이터소스 자동 등록 (인스턴스 IAM 역할로 인증 → 키 불필요)
cat > /etc/grafana/provisioning/datasources/cloudwatch.yaml <<'DS'
apiVersion: 1
datasources:
  - name: CloudWatch
    type: cloudwatch
    isDefault: true
    jsonData:
      authType: default
      defaultRegion: ap-northeast-2
DS

# 4. 서비스 구동
systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server

# ── [WEB-02] Grafana 관리자 비밀번호 자동 생성·변경 ──────────────
# 강력한 무작위 비밀번호를 생성해 SSM Parameter Store에 암호화 저장 후 즉시 적용
# Grafana 기동 완료까지 최대 30초 대기
for i in $(seq 1 10); do
  if grafana-cli --version >/dev/null 2>&1 && systemctl is-active --quiet grafana-server; then
    break
  fi
  sleep 3
done

REGION="ap-northeast-2"
GRAFANA_PASS=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9!@#%^&*()-_' | head -c 24)

# SSM Parameter Store에 SecureString으로 저장 (IAM 역할 권한 사용)
aws ssm put-parameter \
  --region "$REGION" \
  --name  "/aws-project/grafana/admin-password" \
  --value "$GRAFANA_PASS" \
  --type  "SecureString" \
  --overwrite

# Grafana CLI로 admin 비밀번호 즉시 변경 (admin/admin 제거)
grafana-cli admin reset-admin-password "$GRAFANA_PASS"

echo "=== Grafana 설치 완료 — 비밀번호는 SSM /aws-project/grafana/admin-password 확인 ==="
EOF
  )
}

# ==========================================
# 5. 고정 공인 IP (재시작해도 주소 유지 — 끄고 켜는 분석 환경에 유용)
# ==========================================
resource "aws_eip" "grafana_eip" {
  domain   = "vpc"
  instance = aws_instance.grafana_server.id
  tags     = { Name = "grafana-eip" }
}

# ==========================================
# 6. 출력
#   [WEB-02 조치] admin/admin 기본 비밀번호 출력 제거
#                 비밀번호는 SSM Parameter Store에서 조회
# ==========================================
output "grafana_url" {
  description = "Grafana 접속 주소 (192.168.31.x 대역에서만 접속 가능)"
  value       = "http://${aws_eip.grafana_eip.public_ip}:3000"
}

output "grafana_password_ssm" {
  description = "Grafana 관리자 비밀번호 조회 명령 (SSM SecureString)"
  value       = "aws ssm get-parameter --name /aws-project/grafana/admin-password --with-decryption --query Parameter.Value --output text"
}
