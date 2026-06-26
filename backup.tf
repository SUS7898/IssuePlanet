# ==========================================
# backup.tf — 자동 백업 및 Cross-Region 재해복구(DR)
#
# [이 파일의 역할]
#   AWS Backup 을 이용해 EFS(공유 파일)와 RDS(데이터베이스)를 매일 자동으로 백업하고,
#   서울 백업본을 도쿄 DR 저장소로 자동 복제한다.
#
# [백업 흐름]
#   매일 UTC 03:00 (KST 12:00) 백업 실행
#       ↓
#   서울 main-backup-vault 에 저장 → 1일 후 자동 삭제
#       ↓ Cross-Region Copy (자동)
#   도쿄 dr-backup-vault 에 복제 → 7일 후 자동 삭제
#
# [재해복구 시나리오]
#   서울 리전 장애 발생 → 도쿄 vault 의 복구 포인트로 복원 → 서비스 재개
# ==========================================

# ==========================================
# 1. IAM 권한 — AWS Backup 서비스 역할
#    AWS Backup 이 EFS/RDS 에 접근해 백업·복원 작업을 수행하기 위한 권한
# ==========================================
resource "aws_iam_role" "backup_role" {
  name = "aws-backup-role"

  # AWS Backup 서비스가 이 역할을 맡아(AssumeRole) 백업 작업을 실행할 수 있도록 허용
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "backup.amazonaws.com" } }]
  })
}

# 백업 수행 권한 — EFS/RDS 스냅샷 생성, S3 로 데이터 내보내기 등
resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# 복원 권한 — Cross-Region Copy 완료 후 DR 리전에서 복원할 때 필요
resource "aws_iam_role_policy_attachment" "backup_restore_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# ==========================================
# 2. 백업 저장소 (Vault)
#    백업 복구 포인트(스냅샷)가 실제로 저장되는 논리적 컨테이너
# ==========================================

# 서울 메인 저장소 — 매일 백업이 여기에 저장된다
resource "aws_backup_vault" "main_vault" {
  name          = "main-backup-vault"
  force_destroy = true # vault 안에 백업본이 있어도 destroy 시 강제 삭제 허용 (실습 환경용)
}

# 도쿄 DR 저장소 — 서울 백업본이 Cross-Region Copy 로 자동 복제되어 저장된다
# provider = aws.dr : providers.tf 의 도쿄 공급자를 명시적으로 사용
resource "aws_backup_vault" "dr_vault" {
  provider      = aws.dr
  name          = "dr-backup-vault"
  force_destroy = true
}

# ==========================================
# 3. 백업 플랜 — 언제, 어떤 규칙으로 백업할지 정의
# ==========================================
resource "aws_backup_plan" "minimal_backup" {
  name = "minimal-cost-backup-plan"

  rule {
    rule_name         = "daily-1day-retention"
    target_vault_name = aws_backup_vault.main_vault.name
    schedule          = "cron(0 3 * * ? *)" # 매일 UTC 03:00 (KST 12:00) 실행

    # 서울 백업본 보관 기간 — 비용 최소화를 위해 1일만 보관 후 자동 삭제
    lifecycle {
      delete_after = 1
    }

    # Cross-Region Copy — 서울 백업 완료 직후 도쿄 DR vault 로 자동 복제
    # 서울 리전이 완전히 장애 나도 도쿄에서 복원 가능
    copy_action {
      destination_vault_arn = aws_backup_vault.dr_vault.arn

      # DR 복구 여유 시간을 고려해 7일 보관 (서울보다 오래 유지)
      lifecycle {
        delete_after = 7
      }
    }
  }
}

# ==========================================
# 4. 백업 대상 지정 — 어떤 리소스를 백업할지 등록
#    선택된 리소스는 위 플랜의 스케줄·규칙을 그대로 따른다
# ==========================================

# EFS(공유 파일 저장소) 백업 — 사용자 업로드 파일 보호
resource "aws_backup_selection" "efs_backup" {
  name         = "efs-backup-selection"
  iam_role_arn = aws_iam_role.backup_role.arn
  plan_id      = aws_backup_plan.minimal_backup.id
  resources    = [aws_efs_file_system.web_uploads.arn]
}

# RDS(데이터베이스) 백업 — DB 데이터 보호 및 DR 복사
# 이 선택 덕분에 RDS 스냅샷도 도쿄로 자동 복제된다
resource "aws_backup_selection" "rds_backup" {
  name         = "rds-backup-selection"
  iam_role_arn = aws_iam_role.backup_role.arn
  plan_id      = aws_backup_plan.minimal_backup.id
  resources    = [aws_db_instance.primary_db.arn]
}
