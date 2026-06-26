# ==========================================
# outputs.tf — terraform apply 완료 후 출력되는 값
#
# [이 파일의 역할]
#   apply 가 끝나면 터미널에 출력되는 유용한 정보를 모아 둔다.
#   terraform output 명령으로 언제든 다시 조회할 수 있다.
# ==========================================

# ALB(로드밸런서)의 DNS 주소 — Route 53 설정 전에 직접 접속 테스트할 때 사용
output "alb_dns_name" {
  description = "웹 서비스 ALB 주소. Route53 연결 전 직접 접속 테스트용"
  value       = aws_lb.web_alb.dns_name
}

# ==========================================
# 백업 저장소 정보 — 서울(메인) / 도쿄(DR)
#   terraform output 으로 ARN 확인 후 AWS 콘솔에서 복구 포인트 조회 가능
# ==========================================

output "backup_seoul_vault_arn" {
  description = "서울 메인 백업 저장소 ARN (ap-northeast-2)"
  value       = aws_backup_vault.main_vault.arn
}

output "backup_seoul_vault_name" {
  description = "서울 메인 백업 저장소 이름"
  value       = aws_backup_vault.main_vault.name
}

output "backup_tokyo_vault_arn" {
  description = "도쿄 DR 백업 저장소 ARN (ap-northeast-1) — Cross-Region Copy 복구 포인트가 여기에 저장됨"
  value       = aws_backup_vault.dr_vault.arn
}

output "backup_tokyo_vault_name" {
  description = "도쿄 DR 백업 저장소 이름"
  value       = aws_backup_vault.dr_vault.name
}

output "backup_console_seoul" {
  description = "서울 AWS Backup 콘솔 URL — 복구 포인트(스냅샷) 목록 확인"
  value       = "https://ap-northeast-2.console.aws.amazon.com/backup/home?region=ap-northeast-2#/backupvaults/details/${aws_backup_vault.main_vault.name}"
}

output "backup_console_tokyo" {
  description = "도쿄 DR AWS Backup 콘솔 URL — Cross-Region Copy 된 복구 포인트 확인"
  value       = "https://ap-northeast-1.console.aws.amazon.com/backup/home?region=ap-northeast-1#/backupvaults/details/${aws_backup_vault.dr_vault.name}"
}
