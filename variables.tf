# ==========================================
# variables.tf — 프로젝트 공통 입력 변수
#
# [이 파일의 역할]
#   여러 tf 파일에서 반복 사용되는 값을 한 곳에 모아 둔다.
#   terraform apply 시 -var="이름=값" 또는 환경변수 TF_VAR_이름 으로 외부에서 주입한다.
#
# [민감 정보 처리 원칙]
#   비밀번호·계정명은 이 파일에 평문으로 쓰지 않는다.
#   default 를 제거하고 sensitive = true 를 설정해 apply 시 반드시 외부에서 받는다.
# ==========================================

# ==========================================
# 1. 네트워크 대역 (VPC CIDR)
# ==========================================
variable "vpc_cidr" {
  description = "메인 VPC 의 IP 대역. 10.0.0.0/16 = 최대 65,536 개 IP 사용 가능"
  type        = string
  default     = "10.0.0.0/16"
}

# ==========================================
# 2. 데이터베이스 접속 정보
#
# [KISA 조치 이력 — CA-15 / D-03 / D-04 / D-06]
#   db_password : 평문 default 제거 → apply 시 반드시 외부 주입 (하드코딩 금지)
#   db_username : admin 하드코딩 제거 → 변수화 (최소권한 전용 계정 사용 권고)
#   sensitive   : terraform plan/apply 출력에서 값을 *** 로 마스킹
#
# [외부 주입 방법]
#   방법 A — CLI 플래그:
#     terraform apply -var="db_password=강력한비밀번호"
#   방법 B — 환경변수 (CI/CD 파이프라인 권장):
#     export TF_VAR_db_password="강력한비밀번호"
#   방법 C — SSM Parameter Store (가장 안전):
#     export TF_VAR_db_password=$(aws ssm get-parameter \
#       --name "/aws-project/prod/db/password" --with-decryption \
#       --query Parameter.Value --output text)
# ==========================================
variable "db_password" {
  description = "RDS MySQL 접속 비밀번호. 평문 하드코딩 금지 — 반드시 외부에서 주입할 것"
  type        = string
  sensitive   = true # [CA-15/D-03] terraform 출력에서 *** 마스킹
  # default 없음 — apply 시 값을 주지 않으면 Terraform 이 즉시 오류를 낸다
}

variable "db_username" {
  description = "RDS 접속 계정명. 운영 전환 시 admin → appuser 로 변경할 것 (최소권한 원칙)"
  type        = string
  sensitive   = true  # [D-04/D-06] 계정명도 출력에서 마스킹
  default     = "admin"
  # ⚠️ 운영 전환 시 RDS 내부에서 appuser 를 먼저 생성한 뒤 이 값을 변경한다:
  #   CREATE USER 'appuser'@'10.0.%.%' IDENTIFIED BY '<비밀번호>';
  #   GRANT SELECT, INSERT, UPDATE, DELETE ON care.* TO 'appuser'@'10.0.%.%';
  #   FLUSH PRIVILEGES;
}

# ==========================================
# 3. RDS 복원 스냅샷 ID
#
# [동작 방식]
#   비워두면(default = "") rds.tf 의 data.aws_db_snapshot.latest 가 자동으로
#   primary-secure-database 의 최신 스냅샷을 찾아 사용한다.
#   특정 스냅샷으로 고정하고 싶을 때만 값을 넣는다.
#
# [주의] 이미 실행 중인 RDS 가 있으면 lifecycle.ignore_changes 로 보호되므로
#        이 값이 바뀌어도 DB 가 재생성(destroy→create)되지 않는다.
#        이 값은 DB 를 처음 만들거나 재해복구로 새로 생성할 때만 의미가 있다.
# ==========================================
variable "db_restore_snapshot_id" {
  description = "RDS 복원용 스냅샷 ID. 비워두면 primary-secure-database 의 최신 스냅샷을 자동 조회"
  type        = string
  default     = ""
}
