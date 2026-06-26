# ==========================================
# cdn.tf — AWS CloudFront (콘텐츠 전송 네트워크, CDN)
#
# [이 파일의 역할]
#   CloudFront 를 ALB 앞에 배치해 두 가지 효과를 얻는다:
#   1) 정적 파일(업로드 이미지 등)을 엣지 서버에 캐시 → 응답 속도 향상, 오리진 부하 감소
#   2) 사용자 ↔ CDN 구간 HTTPS 를 CloudFront 가 처리 → ALB 의 TLS 부담 감소
#
# [실습 환경 아키텍처]
#   사용자 ──HTTPS──→ CloudFront (*.cloudfront.net) ──HTTP──→ ALB ──→ EC2
#
#   ※ CloudFront → ALB 구간은 HTTP 를 사용한다 (이유: ALB ACM 인증서 도메인 불일치).
#     ALB 의 ACM 인증서는 issueplanet.store 도메인용이지만 CloudFront 가 연결할 때는
#     ALB 의 ELB 도메인(xxx.elb.amazonaws.com)을 사용하므로 HTTPS 검증이 실패한다.
#     운영 환경에서는 us-east-1 에 별도 ACM 인증서를 발급하거나 Custom Origin Header 로
#     CloudFront 전용 요청임을 검증하는 방식을 추가할 수 있다.
#
# [캐시 동작 분리]
#   default_cache_behavior  : 모든 요청 (동적 콘텐츠) → 캐시 없음, 오리진으로 바로 전달
#   ordered_cache_behavior  : /uploads/* (정적 파일)  → 최대 7일 캐시
#
# [비용 참고 — 실습 환경]
#   CloudFront 무료 티어: 매월 1TB 전송 + 1천만 요청 무료 → 실습 트래픽은 무료 수준
# ==========================================

# ==========================================
# 1. AWS 관리형 캐시 정책 참조
#    직접 정책을 만들지 않고 AWS 가 제공하는 최적화된 관리형 정책을 사용한다.
# ==========================================

# CachingDisabled: 캐시하지 않고 모든 요청을 오리진(ALB)으로 그대로 전달
#   Spring Boot 의 동적 페이지, API, 로그인 등에 사용
data "aws_cloudfront_cache_policy" "disabled" {
  name = "Managed-CachingDisabled"
}

# CachingOptimized: 정적 파일에 최적화된 캐시 (기본 TTL 1일, 최대 1년)
#   이미지, CSS, JS 등 자주 바뀌지 않는 파일에 사용
data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

# AllViewer: 사용자의 모든 헤더·쿠키·쿼리스트링을 그대로 오리진으로 전달
#   Spring Session(쿠키), CSRF 토큰, Accept-Language 등이 오리진까지 전달되어야 앱이 정상 동작함
data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}

# ==========================================
# 2. CloudFront 배포(Distribution) 생성
# ==========================================
resource "aws_cloudfront_distribution" "main" {
  enabled         = true          # 배포 즉시 활성화
  is_ipv6_enabled = true          # IPv6 지원
  comment         = "IssuePlanet CDN — ALB origin (HTTP)"
  price_class     = "PriceClass_200" # 북미·유럽·아시아 엣지만 사용 (All 보다 저렴)

  # ──────────────────────────────────────────────────────────────
  # 오리진(Origin) 설정 — CloudFront 가 콘텐츠를 가져올 출발지
  # ──────────────────────────────────────────────────────────────
  origin {
    domain_name = aws_lb.web_alb.dns_name # ALB 의 AWS 자동 생성 도메인
    origin_id   = "alb-origin"            # 이 배포 안에서 오리진을 구분하는 식별자

    custom_origin_config {
      http_port  = 80  # ALB HTTP 리스너 포트
      https_port = 443 # ALB HTTPS 리스너 포트 (현재 미사용)

      # http-only: CloudFront → ALB 구간은 HTTP 사용 (ALB cert 도메인 불일치 회피)
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"] # https-only 로 전환 시 사용할 TLS 버전

      origin_read_timeout      = 30 # 오리진 응답 대기 시간 (초) — Spring Boot 처리 시간 고려
      origin_keepalive_timeout = 5  # 오리진 연결 유지 시간 (초)
    }
  }

  # ──────────────────────────────────────────────────────────────
  # 기본 캐시 동작 — 동적 콘텐츠 (Spring Boot 페이지, API)
  # 캐시 없이 모든 요청을 ALB 로 그대로 전달한다.
  # POST, PUT, DELETE 등 쓰기 요청도 허용 (Spring MVC 폼 처리, REST API)
  # ──────────────────────────────────────────────────────────────
  default_cache_behavior {
    target_origin_id = "alb-origin"

    # 사용자가 HTTP 로 접속하면 자동으로 HTTPS 로 리다이렉트
    viewer_protocol_policy = "redirect-to-https"

    # 읽기 + 쓰기 메서드 모두 허용 (Spring Boot 의 GET/POST/PUT/DELETE 지원)
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD"] # 실제로 캐시되는 메서드 (CachingDisabled 이므로 효과 없음)

    compress = true # gzip/brotli 압축 활성화 → 텍스트 응답 크기 60~80% 감소

    # CachingDisabled: 캐시 없음. 모든 동적 요청을 오리진으로 전달
    cache_policy_id = data.aws_cloudfront_cache_policy.disabled.id

    # AllViewer: 쿠키(세션ID), 헤더(Authorization), 쿼리스트링을 ALB 까지 전달
    # Spring Session / CSRF / Accept-Language 등이 ALB 까지 도달해야 앱이 정상 동작
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
  }

  # ──────────────────────────────────────────────────────────────
  # 정적 파일 캐시 동작 — /uploads/* (EFS 에서 서비스되는 업로드 파일)
  # 이미지, 첨부파일 등은 자주 바뀌지 않으므로 엣지에 캐시한다.
  # 캐시 히트 시 ALB 와 EC2 에 요청이 가지 않아 오리진 부하 감소
  # ──────────────────────────────────────────────────────────────
  ordered_cache_behavior {
    path_pattern     = "/uploads/*" # EFS 업로드 디렉터리 경로 패턴
    target_origin_id = "alb-origin"

    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"] # 정적 파일은 읽기 전용
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    # CachingOptimized: 기본 TTL 1일, 최대 TTL 1년 (파일이 바뀌지 않는다면 장기 캐시)
    cache_policy_id = data.aws_cloudfront_cache_policy.optimized.id
  }

  # ──────────────────────────────────────────────────────────────
  # 지역 제한 없음 — 전 세계 접속 허용
  # ──────────────────────────────────────────────────────────────
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # ──────────────────────────────────────────────────────────────
  # TLS 인증서 — CloudFront 기본 인증서 사용 (실습 환경)
  #
  # cloudfront_default_certificate = true 이면 *.cloudfront.net 인증서를 사용한다.
  # 접속 URL: https://xxxx.cloudfront.net
  #
  # [운영 환경 전환 시]
  # issueplanet.store 도메인을 CloudFront 에 연결하려면:
  #   1) us-east-1 리전에 ACM 인증서를 새로 발급 (CloudFront 는 us-east-1 인증서만 사용)
  #   2) aliases = ["issueplanet.store"] 추가
  #   3) viewer_certificate 블록을 acm_certificate_arn + ssl_support_method 방식으로 교체
  #   4) Route53 A 레코드를 ALB alias → CloudFront alias 로 변경
  # ──────────────────────────────────────────────────────────────
  viewer_certificate {
    cloudfront_default_certificate = true # *.cloudfront.net 기본 인증서 (실습 환경용)
  }

  tags = { Name = "issueplanet-cdn" }
}

# ==========================================
# 3. 출력
# ==========================================
output "cloudfront_domain" {
  description = "CloudFront CDN 접속 주소 — 이 URL 로 브라우저 접속 가능"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront 배포 ID — 캐시 무효화(invalidation) 시 필요"
  value       = aws_cloudfront_distribution.main.id
}
