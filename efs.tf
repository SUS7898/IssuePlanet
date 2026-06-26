# ==========================================
# efs.tf — 공유 파일 저장소 (Amazon EFS)
#
# [이 파일의 역할]
#   웹 서버(EC2)가 여러 대 떠도 업로드 파일을 한 곳에서 공유하기 위한 NFS 저장소를 만든다.
#
# [왜 EFS 가 필요한가?]
#   ASG 로 웹 서버가 2~4 대 동시에 돌아갈 때, 사용자가 A 서버에 파일을 올렸는데
#   다음 요청이 B 서버로 가면 파일을 못 찾는 문제가 생긴다.
#   EFS 를 두면 모든 서버가 같은 파일 시스템을 바라보므로 이 문제가 해결된다.
#
# [마운트 경로]
#   asg.tf 의 user_data 에서 /opt/tomcat/tomcat-10/webapps/uploads 에 자동 마운트
# ==========================================

# ==========================================
# 1. EFS 전용 보안 그룹 (방화벽)
#    NFS 표준 포트(2049)로 들어오는 트래픽을 웹 서버(web_sg)에서만 허용한다.
# ==========================================
resource "aws_security_group" "efs_sg" {
  name        = "efs-sg"
  description = "Allow NFS inbound traffic from Web servers"
  vpc_id      = aws_vpc.primary.id

  # NFS 프로토콜 포트 — 웹 서버 보안 그룹 출발지만 허용
  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "efs-sg" }
}

# ==========================================
# 2. EFS 파일 시스템 본체 생성
#    encrypted = true : 디스크에 저장되는 데이터를 AES-256 으로 암호화
#    lifecycle_policy  : 1일 동안 접근 없는 파일은 저렴한 IA 계층으로 자동 이동 (비용 절감)
# ==========================================
resource "aws_efs_file_system" "web_uploads" {
  creation_token   = "web-uploads-efs" # 중복 생성 방지용 고유 식별자
  encrypted        = true              # [CA-10] 저장 데이터 암호화
  performance_mode = "generalPurpose"  # 일반 웹 서비스에 적합한 성능 모드

  lifecycle_policy {
    transition_to_ia = "AFTER_1_DAY" # 1일 미접근 파일 → Infrequent Access 계층으로 이동
  }

  tags = { Name = "web-uploads-efs" }
}

# ==========================================
# 3. AZ 별 마운트 타겟 생성 (다중 AZ 고가용성)
#
# [마운트 타겟이란?]
#   각 가용 영역(AZ)의 서브넷에 EFS 의 "접속 엔드포인트"를 하나씩 만드는 것.
#   EC2 가 같은 AZ 의 마운트 타겟에 연결하면 AZ 간 데이터 전송 비용이 발생하지 않는다.
#   AZ-A 서버는 efs_target_az1 에, AZ-C 서버는 efs_target_az2 에 자동으로 연결된다.
# ==========================================
resource "aws_efs_mount_target" "efs_target_az1" {
  file_system_id  = aws_efs_file_system.web_uploads.id
  subnet_id       = aws_subnet.private_app_az1.id # AZ-A 의 프라이빗 앱 서브넷
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_efs_mount_target" "efs_target_az2" {
  file_system_id  = aws_efs_file_system.web_uploads.id
  subnet_id       = aws_subnet.private_app_az2.id # AZ-C 의 프라이빗 앱 서브넷
  security_groups = [aws_security_group.efs_sg.id]
}
