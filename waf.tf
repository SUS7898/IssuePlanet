# ==========================================
# waf.tf — AWS WAF v2 (웹 방화벽)
#
# [이 파일의 역할]
#   ALB 앞에 WAF WebACL 을 붙여 악성 요청을 걸러낸다.
#   OWASP Top 10 수준의 기본 공격(SQLi, XSS, 악성 입력)을 AWS 관리형 규칙으로 차단하고,
#   특정 IP 에서 과도한 요청이 들어올 때 자동으로 차단한다.
#
# [WAF 부착 위치]
#   scope = "REGIONAL" → ALB 에 직접 부착 (CloudFront 부착은 CLOUDFRONT + us-east-1 필요)
#   실습 환경에서는 REGIONAL 방식으로 ALB 레벨 보호를 구현한다.
#
# [적용된 규칙 3가지]
#   1) AWSManagedRulesCommonRuleSet    — SQLi, XSS, 경로 순회 등 기본 공격 차단
#   2) AWSManagedRulesKnownBadInputsRuleSet — 알려진 악성 입력 패턴 차단
#   3) RateLimitPerIP                  — IP 당 5분에 2000 요청 초과 시 차단 (DDoS 기본 방어)
#
# [비용 참고 — 실습 환경]
#   WebACL: $5/월 + 관리형 규칙 그룹: $1/월/그룹 = 약 $7/월
#   요청 처리: $0.60/백만 요청 (소규모 실습은 사실상 무료 수준)
# ==========================================

# ==========================================
# 1. WAF WebACL 정의
#    기본 동작(default_action)은 allow — 규칙에 걸리는 요청만 block
# ==========================================
resource "aws_wafv2_web_acl" "main" {
  name        = "main-web-acl"
  description = "Basic WAF for ALB - blocks SQLi, XSS and rate limits per IP"
  scope       = "REGIONAL" # ALB 에 부착할 때는 REGIONAL

  # 규칙에 매칭되지 않은 요청은 기본으로 허용
  default_action {
    allow {}
  }

  # ── Rule 1: AWS 공통 규칙셋 ──────────────────────────────────────
  # OWASP Top 10 기반. SQLi, XSS, 경로 순회, 파일 삽입 등을 탐지/차단한다.
  # override_action = none : AWS 권고 동작(block/count) 을 그대로 따른다.
  rule {
    name     = "AWSCommonRules"
    priority = 1

    override_action {
      none {} # 규칙셋 자체의 block/count 동작을 그대로 사용
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSCommonRules"
      sampled_requests_enabled   = true # CloudWatch 에서 샘플 요청 확인 가능
    }
  }

  # ── Rule 2: 알려진 악성 입력 차단 ────────────────────────────────
  # 악용 가능한 파일 확장자, 로그4j, SSRF 등 특정 패턴의 나쁜 요청을 차단한다.
  rule {
    name     = "KnownBadInputs"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputs"
      sampled_requests_enabled   = true
    }
  }

  # ── Rule 3: IP 당 속도 제한 (기본 DDoS 방어) ──────────────────────
  # 동일 IP 에서 5분간 2000 건을 초과하는 요청이 오면 해당 IP 를 자동으로 차단한다.
  # 정상 사용자는 5분에 2000 건(초당 약 7 건)을 거의 초과하지 않는다.
  rule {
    name     = "RateLimitPerIP"
    priority = 3

    action {
      block {} # 임계값 초과 시 즉시 차단 (429 응답)
    }

    statement {
      rate_based_statement {
        limit              = 2000 # 5분 슬라이딩 윈도우 기준
        aggregate_key_type = "IP" # 출발지 IP 단위로 집계
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitPerIP"
      sampled_requests_enabled   = true
    }
  }

  # WebACL 전체 메트릭 — CloudWatch 에서 총 허용/차단 건수를 확인할 수 있다
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "main-web-acl"
    sampled_requests_enabled   = true
  }

  tags = { Name = "main-web-acl" }
}

# ==========================================
# 2. WAF → ALB 연결
#    이 리소스가 있어야 ALB 로 들어오는 요청에 WAF 가 적용된다.
# ==========================================
resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.web_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

# ==========================================
# 3. WAF 로그 → CloudWatch Logs
#
# [로그 그룹 이름 규칙]
#   AWS 정책상 WAF 로그 그룹 이름은 반드시 "aws-waf-logs-" 로 시작해야 한다.
#   이 규칙을 지키지 않으면 WAF 가 로그를 전송하지 못한다.
# ==========================================
resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-main-web-acl" # 필수 접두사: aws-waf-logs-
  retention_in_days = 7                            # 7일 보관 후 자동 삭제 (비용 절감)
  tags              = { Name = "waf-logs" }
}

# CloudWatch Logs 에 WAF 로그 쓰기를 허용하는 리소스 정책
resource "aws_cloudwatch_log_resource_policy" "waf_logs" {
  policy_name = "waf-logs-cw-policy"
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "delivery.logs.amazonaws.com" }
      Action    = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource  = "${aws_cloudwatch_log_group.waf_logs.arn}:*"
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
      }
    }]
  })
}

# WAF 로깅 설정 — WAF 가 차단/허용한 요청을 위 로그 그룹에 기록
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.main.arn

  depends_on = [aws_cloudwatch_log_resource_policy.waf_logs]
}

# ==========================================
# 4. 출력
# ==========================================
output "waf_web_acl_arn" {
  description = "WAF WebACL ARN"
  value       = aws_wafv2_web_acl.main.arn
}
