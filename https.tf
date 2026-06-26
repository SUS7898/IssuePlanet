# ==========================================
# https.tf — HTTPS 적용 (TLS 인증서 + 도메인 연결)
#
# [이 파일의 역할]
#   웹 서비스에 HTTPS 를 붙이는 데 필요한 세 가지를 구성한다.
#     1) ACM 인증서 ARN 변수     — AWS Certificate Manager 에 미리 발급된 인증서를 참조
#     2) 443 HTTPS 리스너        — ALB 가 HTTPS 요청을 받아 웹 서버로 전달
#     3) Route 53 A 레코드       — 도메인(issueplanet.store) → ALB IP 자동 연결
#
# [선행 조건]
#   이 파일을 apply 하기 전에 아래 두 가지가 AWS 콘솔에서 미리 완료되어야 한다.
#     - ACM 에서 도메인 인증서 발급 (DNS 검증 방식)
#     - Route 53 에 issueplanet.store 호스팅 영역 등록
#
# [HTTP → HTTPS 리다이렉트]
#   80 포트 리스너(web.tf 의 web_listener)가 모든 HTTP 요청을 301 로 443 으로 보낸다.
#   실제 서비스 트래픽은 전부 이 파일의 443 리스너가 처리한다.
# ==========================================

# ACM 인증서 ARN — 서울 리전에서 미리 발급받은 인증서를 변수로 관리
# 인증서가 바뀌면 이 값만 교체하면 된다
variable "acm_certificate_arn" {
  description = "ALB 에 붙일 ACM TLS 인증서 ARN (ap-northeast-2 서울 리전 발급본)"
  type        = string
  default     = "arn:aws:acm:ap-northeast-2:322234947962:certificate/9661b413-b1ae-45aa-a6be-c8fcaa69dad3"
}

# ==========================================
# Route 53 호스팅 영역 참조
# 콘솔에서 미리 만들어 둔 issueplanet.store 호스팅 영역의 ID 를 읽어 온다.
# A 레코드 생성 시 이 zone_id 가 필요하다.
# ==========================================
data "aws_route53_zone" "main" {
  name = "issueplanet.store."
}

# ==========================================
# HTTPS 리스너 (443 포트)
#   ssl_policy   : TLS 1.2/1.3 만 허용하는 AWS 최신 보안 정책 (구형 TLS 1.0/1.1 차단)
#   certificate_arn : 위에서 선언한 ACM 인증서 사용
#   default_action  : 443 으로 들어온 요청을 웹 서버 타겟 그룹(web_tg)으로 전달
# ==========================================
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06" # TLS 1.3 우선, TLS 1.2 허용
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# ==========================================
# Route 53 A 레코드 — 도메인 → ALB alias 연결
#
# [alias 방식을 사용하는 이유]
#   ALB 는 고정 IP 가 없고 내부적으로 IP 가 바뀔 수 있다.
#   alias 를 사용하면 ALB 의 DNS 이름을 바라보므로 IP 가 바뀌어도 자동으로 따라간다.
#   일반 CNAME 과 달리 alias 는 루트 도메인(issueplanet.store)에도 사용할 수 있다.
# ==========================================
resource "aws_route53_record" "root" {
  zone_id         = data.aws_route53_zone.main.zone_id
  name            = "issueplanet.store"
  type            = "A"
  allow_overwrite = true # 콘솔에서 수동으로 만든 레코드가 있어도 덮어쓴다

  alias {
    name                   = aws_lb.web_alb.dns_name
    zone_id                = aws_lb.web_alb.zone_id
    evaluate_target_health = true # ALB 가 비정상이면 Route 53 이 응답을 내보내지 않는다
  }
}

# ==========================================
# 출력 — 최종 서비스 URL
# ==========================================
output "https_url" {
  description = "웹 서비스 최종 접속 주소 (HTTPS)"
  value       = "https://issueplanet.store"
}
