# ==========================================
# sg.tf — 보안 그룹 (방화벽 규칙) 정의
#
# [이 파일의 역할]
#   AWS 보안 그룹은 각 리소스에 붙이는 가상 방화벽이다.
#   어떤 포트로 들어오는 트래픽을 허용할지(ingress)와
#   나가는 트래픽을 허용할지(egress)를 리소스별로 세밀하게 제어한다.
#
# [3-Tier 보안 모델 — 인터넷 → ALB → 웹 서버 → DB]
#   인터넷 사용자
#       ↓  80/443 허용
#   ALB (alb_sg)          ← 인터넷에서 직접 HTTP/HTTPS 만 받는다
#       ↓  8080 허용 (ALB 출발지만)
#   웹 서버 EC2 (web_sg)  ← ALB 를 통과한 트래픽만 받는다. 인터넷 직접 접근 불가
#       ↓  3306 허용 (웹 서버 출발지만)
#   RDS DB (db_sg)        ← 웹 서버 집단에서 오는 MySQL 트래픽만 받는다
#
# 이 구조 덕분에 DB 가 인터넷에 직접 노출되는 일이 원천 차단된다.
# ==========================================

# ==========================================
# 1. ALB(로드밸런서) 보안 그룹
#    인터넷에서 HTTP(80), HTTPS(443) 만 허용한다.
#    web.tf 에서 80 → 443 으로 자동 리다이렉트하므로 실질 서비스는 443 만 사용한다.
# ==========================================
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP inbound traffic from anywhere"
  vpc_id      = aws_vpc.primary.id

  # 전 세계 어디서든 HTTP 로 접속 가능 (443 으로 즉시 리다이렉트됨)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 전 세계 어디서든 HTTPS 로 접속 가능
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ALB 가 백엔드 웹 서버로 트래픽을 전달하기 위해 모든 아웃바운드를 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "alb-sg" }
}

# ==========================================
# 2. 웹 서버(EC2) 보안 그룹
#    인터넷에서 직접 접속하는 것은 불가능하고,
#    오직 alb_sg(로드밸런서)를 출발지로 하는 8080(Tomcat) 트래픽만 허용한다.
# ==========================================
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow Tomcat inbound traffic from ALB"
  vpc_id      = aws_vpc.primary.id

  # ALB 보안 그룹을 출발지로 지정 → ALB 를 통과하지 않은 트래픽은 모두 차단
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # 웹 서버가 외부로 나가는 트래픽 허용 (GitHub clone, dnf 패키지 설치, RDS/Redis 접속 등)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "web-sg" }
}

# ==========================================
# 3. RDS(데이터베이스) 보안 그룹
#    web_sg(웹 서버 집단)에서 출발한 MySQL(3306) 트래픽만 허용한다.
#    인터넷은 물론, 웹 서버 이외의 어떤 AWS 리소스도 DB 에 직접 접속할 수 없다.
# ==========================================
resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "Allow MySQL inbound traffic from Web servers"
  vpc_id      = aws_vpc.primary.id

  # 웹 서버 보안 그룹 출발지만 허용 → DB 로 향하는 모든 직접 접근 원천 차단
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  # [CA-10 조치 2026-06-19] Grafana → RDS 3306 임시 허용 규칙 제거
  # Grafana 는 RDS 에 직접 쿼리하지 않으므로 불필요한 경로를 완전히 차단

  # RDS 가 AWS 내부 API(S3 export, CloudWatch 로그 전송 등)와 통신하기 위해 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "db-sg" }
}
