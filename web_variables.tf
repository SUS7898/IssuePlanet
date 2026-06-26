# ==========================================
# web_variables.tf — 웹 서버(ASG/이미지) 관련 변수
#
# [이 파일의 역할]
#   ASG(자동 확장 서버 그룹)와 골든 AMI(서버 이미지)에 관련된 변수를 모아 둔다.
#   variables.tf 는 건드리지 않고 이 파일만 수정해 웹 서버 설정을 바꿀 수 있다.
# ==========================================

# ==========================================
# 1. 골든 AMI ID (웹 서버 이미지)
#
# [골든 AMI 란?]
#   보안 하드닝·앱 빌드까지 모두 완료된 상태로 "구워진(baked)" 서버 이미지.
#   ASG 가 이 이미지를 찍어 인스턴스를 만들기 때문에
#   새 서버가 뜰 때 별도 설치/배포 없이 바로 서비스 준비 상태가 된다.
#
# [AMI 조회 우선순위]
#   1) 이 변수에 값(ami-xxxx)이 있으면 → 그 AMI 를 그대로 사용 (버전 고정)
#   2) 비어 있으면 → image-builder.tf 의 data.aws_ami.web_latest 가
#      현재 계정에서 이름이 "web-secure-*" 인 가장 최신 AMI 를 자동으로 찾아 사용
#
# [사용 예]
#   최신 자동 조회: default = "" (기본값 유지)
#   버전 고정:      terraform apply -var="web_ami_id=ami-0abc1234def56789"
# ==========================================
variable "web_ami_id" {
  description = "ASG 가 사용할 골든 AMI ID. 비워두면 'web-secure-*' 패턴의 최신 AMI 를 자동 조회한다."
  type        = string
  default     = "" # 비워두면 data.aws_ami.web_latest[0].id 를 자동 사용 (image-builder.tf 참고)
}

# ==========================================
# 2. 애플리케이션 Git 저장소
#
# image-builder.tf 의 빌더 인스턴스가 이 저장소를 clone 해 WAR 파일을 빌드한다.
# 빌드된 WAR 가 골든 AMI 에 포함되어 배포된다.
# ==========================================
variable "app_repo_url" {
  description = "빌더 인스턴스가 clone 할 애플리케이션 Git 저장소 URL"
  type        = string
  default     = "https://github.com/SUS7898/IssuePlanet.git"
}

variable "app_branch" {
  description = "빌더가 빌드할 브랜치 이름"
  type        = string
  default     = "main"
}

# ==========================================
# 3. ASG(Auto Scaling Group) 인스턴스 수 조절
#
# [각 변수의 의미]
#   asg_min     : ASG 가 유지하는 최소 인스턴스 수. 이 수 아래로는 절대 줄어들지 않는다.
#   asg_max     : 트래픽 급증 시 ASG 가 최대로 늘릴 수 있는 인스턴스 수.
#   asg_desired : 평상시 목표 인스턴스 수. 콘솔/CLI 에서 변경해도 apply 가 되돌리지 않는다.
#                 (asg.tf 의 lifecycle.ignore_changes = [desired_capacity] 때문)
#
# [비용 절감 팁]
#   야간·주말에 콘솔에서 desired 를 0 또는 1 로 줄이면 EC2 비용을 대폭 절약할 수 있다.
# ==========================================
variable "asg_min" {
  description = "ASG 최소 인스턴스 수 — 이 수 아래로는 자동 축소되지 않는다"
  type        = number
  default     = 2
}

variable "asg_max" {
  description = "ASG 최대 인스턴스 수 — 트래픽 급증 시 이 수까지 자동 확장된다"
  type        = number
  default     = 4
}

variable "asg_desired" {
  description = "ASG 희망 인스턴스 수 — 평상시 유지 대수. 야간/주말에는 0~1 로 조정 가능"
  type        = number
  default     = 2
}
