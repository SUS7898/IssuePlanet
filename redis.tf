# ==========================================
# redis.tf — 세션 저장소 (Amazon ElastiCache Redis)
#
# [이 파일의 역할]
#   웹 서버 여러 대에서 로그인 세션을 공유하기 위한 Redis 캐시 서버를 만든다.
#
# [왜 Redis 가 필요한가?]
#   사용자가 로그인하면 세션(로그인 상태)이 생성된다.
#   ASG 로 웹 서버가 여러 대일 때, A 서버에서 로그인했는데 다음 요청이 B 서버로 가면
#   세션을 찾지 못해 로그아웃되는 문제가 발생한다.
#   Redis 에 세션을 저장하면 어느 서버로 요청이 가든 같은 세션을 읽을 수 있다.
#
# [연결 흐름]
#   사용자 → ALB → 웹 서버(EC2) ─ 세션 읽기/쓰기 ─→ Redis
#
# [Spring 설정 연동]
#   asg.tf 의 application.properties 에 Redis 주소와 포트가 자동으로 주입된다.
#   spring.session.store-type=redis 설정으로 Spring 이 자동으로 Redis 를 세션 저장소로 사용한다.
# ==========================================

# ==========================================
# 1. Redis 전용 보안 그룹 (방화벽)
#    웹 서버(web_sg) 집단에서 출발한 Redis 표준 포트(6379) 트래픽만 허용한다.
# ==========================================
resource "aws_security_group" "redis_sg" {
  name        = "redis-sg"
  description = "Allow Redis inbound traffic from Web servers"
  vpc_id      = aws_vpc.primary.id

  # Redis 기본 포트 — 웹 서버 보안 그룹 출발지만 허용
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "redis-sg" }
}

# ==========================================
# 2. Redis 서브넷 그룹
#    ElastiCache 가 배치될 서브넷 목록을 미리 그룹으로 등록해 두는 설정.
#    가장 깊숙한 프라이빗 데이터 서브넷(AZ-A, AZ-C)에 Redis 를 격리 배치한다.
# ==========================================
resource "aws_elasticache_subnet_group" "redis_subnets" {
  name       = "web-redis-subnet-group"
  subnet_ids = [aws_subnet.private_data_az1.id, aws_subnet.private_data_az2.id]
}

# ==========================================
# 3. ElastiCache Redis 클러스터
#    node_type     : cache.t3.micro — 프리 티어 및 테스트에 적합한 저사양 노드
#    num_cache_nodes : 1 — 단일 노드 (프리 티어 최적화, 운영 시 3 이상 권장)
#    engine_version  : Redis 7.0 — 세션 저장에 충분한 안정 버전
# ==========================================
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "web-secure-redis"
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.t3.micro" # 프리 티어 사용 가능 사양
  num_cache_nodes      = 1                # 단일 노드 (운영 전환 시 클러스터 모드로 확장 필요)
  parameter_group_name = "default.redis7" # Redis 7.x 기본 설정 그룹
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnets.name
  security_group_ids   = [aws_security_group.redis_sg.id]

  tags = { Name = "web-secure-redis" }
}
