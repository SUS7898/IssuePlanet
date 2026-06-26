# ==========================================
# image-builder.tf — 골든 AMI 제작 빌더 인스턴스
#
# [골든 AMI(Golden AMI)란?]
#   앱 빌드 완료 + 보안 하드닝이 "미리 구워진(baked)" 서버 이미지.
#   ASG 가 이 이미지로 인스턴스를 만들면, 별도 설치·배포 없이 바로 서비스 준비 상태가 된다.
#
# [이 파일의 역할]
#   골든 AMI 를 만들기 위한 "빌더 EC2" 를 생성한다.
#   빌더가 user_data 스크립트로 앱을 빌드하고 보안 설정을 적용한 뒤,
#   관리자가 수동으로 AMI 를 구워서 asg.tf 에 적용한다.
#   AMI 생성 후 빌더는 삭제해도 AMI 는 남는다(Terraform 밖에서 관리).
#
# [AMI 생성·적용 절차]
#   1) terraform apply -target="aws_instance.web_builder"   # 빌더 생성
#   2) SSM 접속 → sudo cloud-init status --wait            # "done" 확인
#   3) aws ec2 create-image --instance-id <id> \
#        --name "web-secure-YYYYMMDD-1" --no-reboot        # 수동 AMI 생성
#   4) terraform apply                                      # 최신 AMI 자동 조회 후 ASG 롤링 배포
#   5) terraform destroy -target="aws_instance.web_builder" # 빌더 삭제 (AMI 는 유지)
#   6) 오래된 AMI 정리 (2개 초과 시):
#        aws ec2 deregister-image --image-id ami-old
#        aws ec2 delete-snapshot --snapshot-id snap-old
# ==========================================

# ==========================================
# 베이스 OS 이미지 조회 — Amazon Linux 2023 최신 버전
#   빌더 인스턴스의 기반 OS. Terraform 이 실행될 때마다 최신 AL2023 AMI 를 자동으로 찾는다.
# ==========================================
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"] # AWS 공식 AMI 만 사용 (서드파티 AMI 제외)
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# ==========================================
# 최신 골든 AMI 자동 조회
#
# [동작 방식]
#   var.web_ami_id 가 비어 있으면 count = 1 → 이 블록이 실행된다.
#   현재 계정(self)에서 이름이 "web-secure-*" 이고 사용 가능한 AMI 중 가장 최신을 찾아온다.
#
#   var.web_ami_id 에 값이 있으면 count = 0 → 이 블록은 완전히 스킵된다(API 호출 없음).
#
# [검색 조건]
#   owners = ["self"]       : 내 계정이 직접 만든 AMI 만 검색 (공개 AMI 제외)
#   name = "web-secure-*"   : image-builder 가 구운 AMI 의 이름 패턴
#   state = "available"     : 아직 생성 중이거나 오류 상태인 AMI 는 제외
# ==========================================
data "aws_ami" "web_latest" {
  count       = var.web_ami_id == "" ? 1 : 0
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["web-secure-*"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}

# ==========================================
# 빌더 EC2 인스턴스
#   이 인스턴스의 user_data 스크립트가 자동으로:
#     1) 런타임 패키지 설치 (Java, Tomcat, Maven 등)
#     2) 앱 소스 코드 clone + Maven 빌드 → ROOT.war 생성
#     3) KISA CII 보안 하드닝 적용
#   완료 후 관리자가 수동으로 AMI 를 찍으면 골든 AMI 가 완성된다.
#
# [왜 Terraform 이 AMI 를 직접 만들지 않나?]
#   Terraform 이 AMI 를 리소스로 관리하면 terraform destroy 시 AMI 도 삭제된다.
#   골든 AMI 는 여러 환경에서 재사용해야 하므로 Terraform 밖(CLI)에서 수동 생성·삭제한다.
# ==========================================
resource "aws_instance" "web_builder" {
  ami                    = data.aws_ami.amazon_linux.id # 최신 AL2023 베이스 이미지
  instance_type          = "t3.small"  # Maven 빌드용 — t3.micro 는 메모리 부족으로 OOM 발생
  key_name               = "aws-project"
  subnet_id              = aws_subnet.private_app_az1.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  depends_on = [aws_nat_gateway.nat] # NAT Gateway 가 먼저 있어야 인터넷(GitHub, dnf 등) 접근 가능

  tags = { Name = "web-golden-builder" }

  user_data = base64encode(<<-EOT
#!/bin/bash
set -xe
echo "=== golden image bake start ==="

# 0. swap 2GB 생성 — Maven 빌드 시 메모리 부족(OOM) 방지
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# 1. 런타임·빌드 패키지 설치
dnf update -y
dnf install -y amazon-efs-utils java-17-amazon-corretto-devel git maven tar gzip wget amazon-cloudwatch-agent mariadb105

# 2. Tomcat 10 설치
#    /opt/tomcat/tomcat-10 에 압축 해제, 전용 시스템 계정(tomcat) 생성
mkdir -p /opt/tomcat/tomcat-10
wget -q https://archive.apache.org/dist/tomcat/tomcat-10/v10.1.19/bin/apache-tomcat-10.1.19.tar.gz
tar xzf apache-tomcat-10.1.19.tar.gz -C /opt/tomcat/tomcat-10 --strip-components=1
useradd -m -U -d /opt/tomcat -s /bin/false tomcat || true # 로그인 불가 전용 서비스 계정

# 3. 디렉터리 구조 및 환경 파일 초기화
mkdir -p /opt/app/bin /opt/app/config /etc/gitops
echo "REPO_DIR=/opt/app/src"        >  /etc/gitops/env
echo "APP_BRANCH=${var.app_branch}" >> /etc/gitops/env

# 4. 정적 설정 파일들을 AMI 에 베이크(bake)
#    base64 로 인코딩해서 Terraform 문자열 안에 안전하게 포함시키는 방식
echo "${base64encode(file("${path.module}/files/tomcat.service"))}" | base64 -d > /etc/systemd/system/tomcat.service
echo "${base64encode(file("${path.module}/files/setenv.sh"))}"      | base64 -d > /opt/tomcat/tomcat-10/bin/setenv.sh
echo "${base64encode(file("${path.module}/files/deploy.sh"))}"      | base64 -d > /opt/app/bin/deploy.sh
echo "${base64encode(file("${path.module}/files/cloudwatch-agent.json"))}" | base64 -d > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
chmod +x /opt/tomcat/tomcat-10/bin/setenv.sh /opt/app/bin/deploy.sh

# 5. 앱 소스 clone + Maven 빌드 → ROOT.war 를 Tomcat webapps 에 배포
#    이 WAR 가 골든 AMI 에 포함되므로 새 서버가 뜰 때 빌드 없이 바로 실행된다
export HOME=/root
git config --system --add safe.directory /opt/app/src
git clone --branch ${var.app_branch} ${var.app_repo_url} /opt/app/src
cd /opt/app/src
mvn -q clean package -DskipTests
WAR=$(ls -1 target/*.war | grep -v '\.original$' | head -n1)
rm -rf /opt/tomcat/tomcat-10/webapps/ROOT*
cp "$WAR" /opt/tomcat/tomcat-10/webapps/ROOT.war

# ============================================================
# 6. KISA CII 보안 하드닝
#    아래 각 설정은 KISA 기술적 취약점 분석·평가 항목을 기준으로 적용한다
# ============================================================

# ── [WEB-07 / WEB-15] 불필요한 Tomcat 기본 앱 제거 ─────────────
# manager/host-manager : 관리자 콘솔 → 공격 대상이 되므로 제거
# docs/examples        : 버전 정보와 취약 샘플 코드가 노출되므로 제거
rm -rf /opt/tomcat/tomcat-10/webapps/manager \
       /opt/tomcat/tomcat-10/webapps/host-manager \
       /opt/tomcat/tomcat-10/webapps/docs \
       /opt/tomcat/tomcat-10/webapps/examples

# ── [WEB-16] Server·X-Powered-By 응답 헤더 버전 정보 제거 ───────
# ── [WEB-22] ErrorReportValve: 에러 응답에 스택 트레이스 미포함 ───
# ── [WEB-13] TCP Shutdown 포트(-1) 비활성화 — 원격 종료 공격 방지 ─
python3 -c "
import re

SERVER_XML = '/opt/tomcat/tomcat-10/conf/server.xml'
c = open(SERVER_XML).read()

# Connector: 버전 헤더 제거 (server 속성을 공백으로, X-Powered-By 비활성)
c = re.sub(
    r'(<Connector port=\"8080\")',
    r'\1 server=\" \" xpoweredBy=\"false\"',
    c
)

# Server 요소: TCP shutdown 포트 비활성화 (-1 = 비활성, DISABLED = 임의 명령 무효화)
c = re.sub(
    r'<Server port=\"\d+\" shutdown=\"SHUTDOWN\">',
    '<Server port=\"-1\" shutdown=\"DISABLED\">',
    c
)

# ErrorReportValve: HTML 에러 페이지에서 스택 트레이스와 서버 버전 정보 제거
if 'ErrorReportValve' not in c:
    c = re.sub(
        r'(<Host\s[^>]*>)',
        r'\1\n        <Valve className=\"org.apache.catalina.valves.ErrorReportValve\"\n              showReport=\"false\" showServerInfo=\"false\" />',
        c
    )

open(SERVER_XML, 'w').write(c)
print('[WEB-13/WEB-16/WEB-22] server.xml 보안 설정 완료')
"

# ── [WEB-04] 디렉터리 리스팅 명시적 비활성화 ─────────────────────
# Tomcat 기본값도 false 이지만, 설정 변경으로 되돌리는 것을 방지하기 위해 명시적으로 고정
python3 -c "
import re
path = '/opt/tomcat/tomcat-10/conf/web.xml'
c = open(path).read()
c = re.sub(
    r'(<param-name>listings</param-name>\s*<param-value>)\w+(</param-value>)',
    r'\1false\2',
    c
)
open(path, 'w').write(c)
print('[WEB-04] 디렉터리 리스팅 비활성화 완료')
"

# ── [U-30] UMASK 강화 — 신규 생성 파일의 기타 사용자 읽기 권한 제거 ─
# 기본 022(rw-r--r--) → 027(rw-r-----) : other 읽기 권한 제거
printf 'umask 027\n' > /etc/profile.d/00-secure-umask.sh
chmod 644 /etc/profile.d/00-secure-umask.sh

# ── [U-02] OS 비밀번호 정책 강화 (KISA 권고: 최대 90일, 최소 8자) ──
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   1/'  /etc/login.defs
sed -i 's/^PASS_MIN_LEN.*/PASS_MIN_LEN    8/'   /etc/login.defs

# ── [U-03] 계정 잠금 — 5회 연속 실패 시 300초(5분) 잠금 ───────────
# KISA 권고: 로그인 5회 이상 연속 실패 시 계정 잠금
printf 'deny = 5\nfail_interval = 900\nunlock_time = 300\n' \
  > /etc/security/faillock.conf
authselect enable-feature with-faillock --force 2>/dev/null || true

# ── [U-67] Tomcat 설정·로그 디렉터리 권한 최소화 ────────────────
# conf 디렉터리: root 소유, tomcat 그룹만 읽기 가능 (일반 계정 접근 차단)
# logs 디렉터리: tomcat 소유, 750 (외부 노출 차단)
chown root:tomcat /opt/tomcat/tomcat-10/conf
chmod 750         /opt/tomcat/tomcat-10/conf
find /opt/tomcat/tomcat-10/conf -maxdepth 1 -type f -exec chmod 640 {} \;
chown -R tomcat:tomcat /opt/tomcat/tomcat-10/logs
chmod 750              /opt/tomcat/tomcat-10/logs
# ============================================================

chown -R tomcat:tomcat /opt/tomcat /opt/app
chmod -R u+x /opt/tomcat/tomcat-10/bin

# 7. 서비스는 설치만 하고 자동시작은 끔
#    실제 기동은 asg.tf 의 user_data(런타임 단계)에서 `systemctl enable --now tomcat` 으로 처리
systemctl daemon-reload
systemctl disable tomcat || true

echo "=== golden image bake done ==="
EOT
  )
}
