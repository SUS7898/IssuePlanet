# ==========================================
# asg.tf — 웹 서버 자동 확장 그룹 (ASG + 무중단 롤링 배포)
#
# [이 파일의 역할]
#   웹 서버 인스턴스를 자동으로 늘리고 줄이는 ASG 와,
#   새 AMI 를 배포할 때 무중단으로 서버를 교체하는 롤링 배포 설정을 담당한다.
#
# [핵심 개념]
#   Launch Template : "어떤 AMI 로, 어떤 사양으로, 어떤 설정으로 서버를 띄울지" 정의하는 설계도
#   ASG             : Launch Template 을 보고 실제 서버를 몇 대 띄울지 관리하는 자동화 장치
#   instance_refresh : 새 Launch Template 이 배포되면 기존 서버를 한 대씩 교체 (서비스 중단 없음)
#
# [무중단 배포 흐름]
#   1) image-builder.tf 의 빌더 인스턴스에서 앱을 빌드하고 보안 하드닝 적용
#   2) CLI 로 AMI 생성: aws ec2 create-image --name "web-secure-YYYYMMDD" ...
#   3) terraform apply → local.web_ami_id 가 최신 web-secure-* AMI 자동 조회
#   4) Launch Template 새 버전 생성 → ASG 가 기존 서버를 한 대씩 새 AMI 로 교체 (무중단)
#   특정 버전 고정: terraform apply -var="web_ami_id=ami-xxxx"
#
# [AMI 선택 우선순위]
#   var.web_ami_id 에 값이 있으면 → 그 AMI 사용 (버전 고정)
#   var.web_ami_id 가 비어 있으면 → data.aws_ami.web_latest 로 web-secure-* 최신 AMI 자동 조회
# ==========================================

# Launch Template 에서 사용할 AMI ID 를 결정
# 명시적 변수 값이 있으면 우선 사용, 없으면 최신 골든 AMI 자동 조회
locals {
  web_ami_id = var.web_ami_id != "" ? var.web_ami_id : data.aws_ami.web_latest[0].id
}

# ==========================================
# Launch Template — 서버 생성 설계도
#   이 설계도를 바탕으로 ASG 가 실제 EC2 인스턴스를 만든다.
#   이미지(AMI), 사양(instance_type), 네트워크, 보안 설정이 모두 여기서 정의된다.
# ==========================================
resource "aws_launch_template" "web" {
  name_prefix   = "web-lt-"       # Terraform 이 버전마다 고유 이름을 자동 생성
  image_id      = local.web_ami_id # 위에서 결정한 골든 AMI 사용
  instance_type = "t3.micro"
  key_name      = "aws-project"   # SSH 키 — SSM 을 주로 쓰지만 비상용으로 유지

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # SSM 접속 + CloudWatch 로그 전송 권한을 부여하는 IAM 프로파일
  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_profile.name
  }

  # [CA-17] IMDSv2 강제 — http_tokens = "required"
  # SSRF 공격으로 메타데이터 API 에 접근해도 IAM 자격증명을 탈취할 수 없게 한다
  metadata_options {
    http_tokens   = "required" # IMDSv2 토큰 없이는 메타데이터 조회 불가
    http_endpoint = "enabled"
  }

  # ==========================================
  # user_data — 인스턴스가 처음 부팅될 때 딱 한 번 실행되는 초기화 스크립트
  #
  # [역할] AMI 에 이미 구워진 앱을 "런타임 환경"에 맞게 설정하고 기동한다.
  #        빌드나 배포는 하지 않는다 — AMI 에 이미 ROOT.war 가 포함되어 있다.
  # ==========================================
  user_data = base64encode(<<-EOT
#!/bin/bash
set -xe

# 1) EFS 업로드 공유 폴더 마운트
#    ASG 의 모든 서버가 같은 EFS 를 마운트하므로 어느 서버에서 올린 파일도 공유된다
mkdir -p /opt/tomcat/tomcat-10/webapps/uploads
echo "${aws_efs_file_system.web_uploads.id}:/ /opt/tomcat/tomcat-10/webapps/uploads efs _netdev,noresvport,tls 0 0" >> /etc/fstab
mount -a || true

# 2) 외부 설정 주입 — WAR 내부의 application.properties 보다 이 파일이 우선 적용된다
#    DB 주소, Redis 주소 등 환경별로 다른 값을 여기서 런타임에 주입한다
cat > /opt/app/config/application.properties <<'PROPS'
spring.datasource.driver-class-name=org.mariadb.jdbc.Driver
spring.datasource.username=${var.db_username}
spring.datasource.password=${var.db_password}
spring.datasource.url=jdbc:mariadb://${aws_db_instance.primary_db.address}:3306/care?sslMode=trust&serverTimezone=Asia/Seoul&characterEncoding=UTF-8
spring.data.redis.host=${aws_elasticache_cluster.redis.cache_nodes[0].address}
spring.data.redis.port=6379
spring.session.store-type=redis
server.port=8080
PROPS
# [CA-16/D-16] sslMode=trust : 앱↔DB 전송 구간 TLS 암호화 (평문 전송 방지)
# [D-04/D-06]  username 을 변수로 주입 (admin 하드코딩 제거, appuser 전환 가능)
# [D-13]       allowPublicKeyRetrieval 옵션 제거 (불필요한 옵션 차단)
chown -R tomcat:tomcat /opt/app/config /opt/tomcat/tomcat-10/webapps

# 3) Tomcat 서비스 기동 — AMI 에 이미 빌드된 ROOT.war 로 즉시 서비스 시작
systemctl enable --now tomcat

# 4) CloudWatch 로그 에이전트 기동 — 설정 파일은 AMI 에 이미 포함되어 있음
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s || true
EOT
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "web-asg" }
  }

  # 새 버전의 Launch Template 을 먼저 만든 뒤 이전 버전을 삭제 — 배포 중 공백 방지
  lifecycle {
    create_before_destroy = true
  }
}

# ==========================================
# Auto Scaling Group — 서버 대수 자동 관리
#
# min_size     : 트래픽이 없어도 최소 이 수만큼은 항상 유지
# max_size     : 트래픽이 폭증해도 이 수를 초과하여 확장하지 않음
# desired_capacity : 평상시 목표 대수 (콘솔에서 바꿔도 apply 가 되돌리지 않음)
# ==========================================
resource "aws_autoscaling_group" "web" {
  name_prefix         = "web-asg-"
  min_size            = var.asg_min
  max_size            = var.asg_max
  desired_capacity    = var.asg_desired
  vpc_zone_identifier = [aws_subnet.private_app_az1.id, aws_subnet.private_app_az2.id]
  target_group_arns   = [aws_lb_target_group.web_tg.arn] # ALB 가 이 ASG 로 트래픽을 분산

  # ALB 헬스체크 기준 — 새 인스턴스가 ALB 헬스체크를 통과해야 정상으로 인정
  # 비정상 인스턴스는 ALB 가 자동으로 제외하고 ASG 가 새 인스턴스로 교체
  health_check_type         = "ELB"
  health_check_grace_period = 180 # 부팅 직후 180초는 헬스체크 실패를 무시 (앱 기동 시간)

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest" # 항상 최신 버전의 Launch Template 사용
  }

  # ==========================================
  # instance_refresh — 무중단 롤링 배포
  #   Launch Template 이 바뀌면(새 AMI 등) 기존 서버를 한 대씩 교체한다.
  #   min_healthy_percentage = 50 : 교체 중에도 전체의 50% 이상은 항상 정상 운영
  #   instance_warmup = 120       : 새 서버가 뜨고 나서 120초 후 다음 서버 교체 시작
  # ==========================================
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 120
    }
    triggers = ["launch_template"] # Launch Template 이 바뀔 때만 롤링 교체 발동
  }

  # 콘솔이나 CLI 로 desired_capacity 를 수동으로 바꿔도 apply 가 되돌리지 않는다
  # (야간·주말 비용 절감을 위해 콘솔에서 0으로 줄이는 경우를 보호)
  lifecycle {
    ignore_changes = [desired_capacity]
  }

  # NAT Gateway 와 EFS 마운트 타겟이 먼저 준비된 뒤에 ASG 를 생성
  depends_on = [
    aws_nat_gateway.nat,
    aws_efs_mount_target.efs_target_az1,
    aws_efs_mount_target.efs_target_az2,
  ]

  tag {
    key                 = "Name"
    value               = "web-asg"
    propagate_at_launch = true # 이 태그를 ASG 가 만드는 EC2 인스턴스에도 자동으로 붙인다
  }
}
