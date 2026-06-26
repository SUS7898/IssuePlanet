# ==========================================
# providers.tf — Terraform 실행 환경 설정
#
# [이 파일의 역할]
#   Terraform이 "어떤 클라우드(AWS)를, 어느 지역에서" 작업할지 선언한다.
#   코드를 실행하기 전에 가장 먼저 읽히는 설정 파일이다.
#
# [리전 구성]
#   기본(default) : ap-northeast-2 서울 — 실제 서비스가 돌아가는 메인 리전
#   별칭(dr)      : ap-northeast-1 도쿄 — 재해복구(DR) 백업 저장소에만 사용하는 보조 리전
# ==========================================

terraform {
  # 사용할 AWS 공급자(Provider)의 버전 범위를 고정한다.
  # ~> 5.0 의 의미: 5.x 대 최신 버전을 자동 사용하되, 6.0 이상은 차단 (하위 호환 보장)
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ==========================================
# 기본 공급자 — 서울 리전 (ap-northeast-2)
#
# 이 블록에서 지정한 리전이 모든 리소스의 기본 생성 위치가 된다.
# provider = 를 별도로 지정하지 않은 리소스는 전부 서울에 만들어진다.
# ==========================================
provider "aws" {
  region = "ap-northeast-2"

  # 이 블록에 선언한 태그는 이 프로젝트에서 생성되는 모든 AWS 리소스에 자동으로 붙는다.
  # AWS 비용 탐색기(Cost Explorer)나 콘솔에서 프로젝트별 자원·요금을 쉽게 필터링할 수 있다.
  default_tags {
    tags = {
      Project     = "Infra-Sec-DR"
      Environment = "Production"
    }
  }
}

# ==========================================
# DR 리전 공급자 — 도쿄 (ap-northeast-1)
#
# alias = "dr" 로 이름을 붙여 두면, 다른 tf 파일에서
# `provider = aws.dr` 를 명시하는 리소스만 이 리전에 생성된다.
# backup.tf 의 DR 백업 저장소(aws_backup_vault.dr_vault)가 이 공급자를 사용한다.
# 도쿄는 서울과 가장 가까운 리전이라 재해 복구 시 복원 속도가 빠르다.
# ==========================================
provider "aws" {
  alias  = "dr"
  region = "ap-northeast-1"

  default_tags {
    tags = {
      Project     = "Infra-Sec-DR"
      Environment = "Production"
    }
  }
}
