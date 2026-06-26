# ==========================================
# web.tf  (방식 B: 무중단 = 이미지 롤링/ASG)
# - 단일 인스턴스는 제거하고 asg.tf 로 옮김
# - 여기에는 ALB + 타깃그룹 + 리스너 + IAM + ALB 로그 S3 만 남긴다
#
# [CA-11 / WEB-26 조치] 2026-06-19
#   ALB 액세스 로그 활성화 — S3 버킷 생성 + 버킷 정책 + access_logs 블록 추가
# ==========================================

# -----------------------------------------
# 0. 계정 정보 (ALB 로그 S3 버킷 정책에 사용)
# -----------------------------------------
data "aws_caller_identity" "current" {}

# -----------------------------------------
# 1. IAM (SSM 접속 + CloudWatch 로그 전송)
# -----------------------------------------
resource "aws_iam_role" "ssm_role" {
  name = "web-ssm-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cw_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "web-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

# -----------------------------------------
# 2. ALB 액세스 로그용 S3 버킷 [CA-11 / WEB-26 조치]
#    모든 ALB 요청 기록 → 침해사고 분석, 비정상 트래픽 탐지
# -----------------------------------------
resource "aws_s3_bucket" "alb_logs" {
  bucket        = "aws-project-alb-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = { Name = "alb-access-logs" }
}

# 퍼블릭 접근 전면 차단
resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket                  = aws_s3_bucket.alb_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 서버 사이드 암호화 (AES-256)
resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 30일 후 자동 삭제 (로그 보관 기간 정책)
resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  rule {
    id     = "expire-alb-logs"
    status = "Enabled"
    expiration {
      days = 90
    }
  }
}

# ALB 로그 기록 허용 버킷 정책
#   - ap-northeast-2(서울) ELB 서비스 계정: 600734575887
#   - delivery.logs.amazonaws.com 서비스 주체도 함께 허용 (신규 방식)
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "logdelivery.elasticloadbalancing.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.alb_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.alb_logs]
}

# -----------------------------------------
# 3. 로드밸런서 (ALB)
# -----------------------------------------
resource "aws_lb" "web_alb" {
  name               = "web-multi-az-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_az1.id, aws_subnet.public_az2.id]

  # [CA-11 / WEB-26 조치] ALB 액세스 로그 활성화
  access_logs {
    bucket  = aws_s3_bucket.alb_logs.id
    enabled = true
  }

  depends_on = [aws_s3_bucket_policy.alb_logs]
}

resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.primary.id

  health_check {
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }

  deregistration_delay = 30
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  # CloudFront 가 사용자 ↔ CDN 구간 HTTPS 를 처리하고, CDN → ALB 는 HTTP 로 연결한다.
  # CloudFront 없이 ALB 에 직접 접속할 때도 HTTPS 는 포트 443 리스너가 처리한다.
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# -----------------------------------------
# 4. 출력
# -----------------------------------------
output "alb_dns_address" {
  description = "웹 서비스 접속용 로드밸런서 주소"
  value       = aws_lb.web_alb.dns_name
}

output "alb_logs_bucket" {
  description = "ALB 액세스 로그 S3 버킷"
  value       = aws_s3_bucket.alb_logs.id
}
