# ==========================================
# rds.tf — 관계형 데이터베이스 (Amazon RDS MySQL 8.0)
#
# [이 파일의 역할]
#   애플리케이션 데이터(게시글, 회원 정보 등)를 저장하는 MySQL DB 를 생성한다.
#   스냅샷에서 복원하는 방식이므로 초기 스키마와 데이터가 함께 로드된다.
#
# [보안 구성 요약]
#   - 인터넷에서 직접 접속 불가 (publicly_accessible = false)
#   - 저장 데이터 암호화 (storage_encrypted = true)
#   - 앱↔DB 전송 암호화 (asg.tf 의 sslMode=trust)
#   - 로그인 실패 10회 시 호스트 차단 (max_connect_errors = 10) [D-09]
#   - 전체 쿼리 감사 로그 → CloudWatch Logs 전송 [D-26]
# ==========================================

# ==========================================
# 0. 최신 RDS 스냅샷 자동 조회
#
# [동작 방식]
#   var.db_restore_snapshot_id 가 비어 있으면 count = 1 이 되어 이 블록이 실행된다.
#   primary-secure-database 의 가장 최신 스냅샷 ID 를 자동으로 찾아 local.rds_snapshot_id 에 넣는다.
#   var.db_restore_snapshot_id 에 값이 있으면 count = 0 → 이 블록은 완전히 스킵되고
#   API 호출도 발생하지 않는다.
#
# [실행 중인 DB 에 미치는 영향]
#   lifecycle.ignore_changes = [snapshot_identifier] 덕분에
#   이 값이 바뀌어도 기존 DB 는 삭제·재생성되지 않는다. 완전히 안전하다.
# ==========================================
data "aws_db_snapshot" "latest" {
  count                  = var.db_restore_snapshot_id == "" ? 1 : 0
  most_recent            = true
  db_instance_identifier = "primary-secure-database"
}

# 사용할 스냅샷 ID 를 결정 — 명시적 변수 값이 있으면 우선, 없으면 자동 조회 결과 사용
locals {
  rds_snapshot_id = var.db_restore_snapshot_id != "" ? var.db_restore_snapshot_id : data.aws_db_snapshot.latest[0].id
}

# ==========================================
# 1. DB 서브넷 그룹
#    RDS 가 배치될 서브넷 범위를 등록한다.
#    가용 영역 A, C 의 가장 깊은 프라이빗 데이터 서브넷에 DB 를 격리한다.
# ==========================================
resource "aws_db_subnet_group" "db_subnets" {
  name       = "primary-db-subnet-group"
  subnet_ids = [aws_subnet.private_data_az1.id, aws_subnet.private_data_az2.id]
  tags       = { Name = "My DB subnet group" }
}

# ==========================================
# 2. DB 파라미터 그룹 — KISA CII 보안 설정 + 감사 로그
#
# [KISA 취약점 조치 이력]
#   D-09 / BF : max_connect_errors 1000000000 → 10 (브루트포스 로그인 차단)
#   D-26      : general_log 0 → 1 (전체 쿼리 감사 로그 활성화)
#   추가 보안  : local_infile = 0 (로컬 파일 읽기 공격 경로 차단)
#
# [주의] general_log=1 은 모든 SQL 쿼리를 기록하므로 I/O 부하와 CloudWatch 비용이 증가한다.
#        보안 감사 완료 후 0 으로 되돌리는 것을 권장한다.
# ==========================================
resource "aws_db_parameter_group" "mysql_logs" {
  name   = "primary-db-logs-pg"
  family = "mysql8.0"

  # ── 로그 설정 ────────────────────────────────────────
  parameter {
    name  = "general_log"
    value = "1" # [D-26] 모든 SQL 쿼리 감사 로그 활성화
  }
  parameter {
    name  = "slow_query_log"
    value = "1" # 1초 이상 걸리는 슬로우 쿼리 기록 (성능 병목 분석용)
  }
  parameter {
    name  = "long_query_time"
    value = "1" # 슬로우 쿼리 기준: 1초 이상
  }
  parameter {
    name  = "log_output"
    value = "FILE" # 로그를 파일에 기록 → CloudWatch Logs 로 전송
  }

  # ── 보안 설정 ────────────────────────────────────────
  parameter {
    name  = "max_connect_errors"
    value = "10" # [D-09/BF] 연속 10회 로그인 실패 시 해당 호스트 차단
  }
  parameter {
    name  = "local_infile"
    value = "0" # LOAD DATA LOCAL INFILE 비활성화 — 로컬 파일 읽기 공격 경로 차단
  }

  tags = { Name = "primary-db-logs-pg" }
}

# ==========================================
# 3. RDS 인스턴스 생성
#
# [스냅샷 복원 방식]
#   snapshot_identifier 를 지정하면 빈 DB 대신 스냅샷 상태 그대로 복원된다.
#   care DB 와 테이블이 이미 만들어진 상태로 시작하므로 별도 스키마 초기화가 필요 없다.
#
# [lifecycle.ignore_changes = [snapshot_identifier]]
#   snapshot_identifier 는 DB 최초 생성 시에만 의미가 있다.
#   이 설정이 없으면 스냅샷 ID 가 변경될 때마다 Terraform 이 DB 를 삭제하고 다시 만들려 한다.
#   데이터 손실을 막기 위해 이 필드의 변경은 Terraform 이 무시하도록 설정한다.
# ==========================================
resource "aws_db_instance" "primary_db" {
  identifier     = "primary-secure-database"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro" # 프리 티어 사용 가능 사양

  allocated_storage = 20        # 기본 스토리지 20 GB
  storage_encrypted = true      # [CA-10/D-08] 디스크 암호화 — 물리 탈취 시에도 데이터 보호

  username               = "admin"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  snapshot_identifier  = local.rds_snapshot_id  # 스냅샷에서 복원 (초기 데이터 포함)
  parameter_group_name = aws_db_parameter_group.mysql_logs.name

  # 지정한 로그(오류·전체쿼리·슬로우)를 CloudWatch Logs 로 실시간 전송
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  # 유지보수 창을 기다리지 않고 파라미터 변경 사항을 즉시 DB 에 적용
  apply_immediately = true

  # ── 비용 및 보안 옵션 ──────────────────────────────────
  multi_az            = true  # 다중 AZ 구성 — Standby 자동 생성 및 페일오버 활성화
  publicly_accessible = false # [D-10] 인터넷에서 DB 에 직접 접속 불가 — 핵심 보안 설정
  skip_final_snapshot = true  # destroy 시 최종 스냅샷 생성 생략 (실습 환경용)

  # RDS 자체 자동 백업 — AWS Backup 과 별개로 RDS 네이티브 스냅샷도 1일 보관
  backup_retention_period = 1
  backup_window           = "17:00-17:30" # UTC 기준 백업 창 (KST 02:00~02:30)

  lifecycle {
    # snapshot_identifier 는 최초 생성 시에만 사용 → 이후 변경은 무시해 재생성 방지
    ignore_changes = [snapshot_identifier]
  }
}
