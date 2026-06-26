# ==========================================
# 1. 메인 VPC (가상 사설망) 생성
# ==========================================
resource "aws_vpc" "primary" {
  cidr_block           = var.vpc_cidr # variables.tf의 10.0.0.0/16 대역 사용
  enable_dns_hostnames = true         # 내부 서버들이 퍼블릭 DNS 주소를 가질 수 있도록 허용
  enable_dns_support   = true         # AWS 기본 DNS 서버(Route 53 Resolver) 사용 허용

  tags = { Name = "primary-vpc" }
}

# ==========================================
# 2. 인터넷 게이트웨이 (외부 접속 통로)
# ==========================================
# VPC 내부의 자원들이 외부 인터넷과 통신할 수 있게 해주는 출입구입니다.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.primary.id
  tags   = { Name = "primary-igw" }
}

# ==========================================
# 3. 가용 영역 A (AZ-A) - 서브넷 망 분리
# ==========================================
# 3-1. 퍼블릭 서브넷: 로드밸런서(ALB)가 배치되어 사용자의 접속을 직접 받는 곳입니다.
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.primary.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true # 이곳에 생성된 자원은 자동으로 공인 IP를 받습니다.
  tags                    = { Name = "public-subnet-az1" }
}

# 3-2. 프라이빗 App 서브넷: 인터넷이 직접 닿지 않는 안전한 곳. 톰캣 웹 서버(EC2)가 배치됩니다.
resource "aws_subnet" "private_app_az1" {
  vpc_id            = aws_vpc.primary.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "ap-northeast-2a"
  tags              = { Name = "private-app-subnet-az1" }
}

# 3-3. 프라이빗 Data 서브넷: 가장 깊숙한 곳. 해킹을 막기 위해 데이터베이스(RDS)만 배치됩니다.
resource "aws_subnet" "private_data_az1" {
  vpc_id            = aws_vpc.primary.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "ap-northeast-2a"
  tags              = { Name = "private-data-subnet-az1" }
}

# ==========================================
# 4. 가용 영역 C (AZ-C) - 이중화(재해 복구)
# ==========================================
# AZ-A 데이터센터에 화재나 정전이 발생해도 서비스가 멈추지 않도록 똑같은 구조를 만듭니다.
resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.primary.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true
  tags                    = { Name = "public-subnet-az2" }
}

resource "aws_subnet" "private_app_az2" {
  vpc_id            = aws_vpc.primary.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-northeast-2c"
  tags              = { Name = "private-app-subnet-az2" }
}

resource "aws_subnet" "private_data_az2" {
  vpc_id            = aws_vpc.primary.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "ap-northeast-2c"
  tags              = { Name = "private-data-subnet-az2" }
}

# ==========================================
# 5. NAT 게이트웨이 및 라우팅 설정
# ==========================================
# 인터넷이 끊긴 프라이빗 서브넷 안의 EC2가 깃허브 코드를 다운받기 위해 필요한 '단방향 아웃바운드 통로'입니다.

# 5-1. NAT 게이트웨이가 사용할 고정 공인 IP 발급
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# 5-2. NAT 게이트웨이 생성 (반드시 외부와 통신 가능한 퍼블릭 서브넷에 두어야 합니다.)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_az1.id
  depends_on    = [aws_internet_gateway.igw] # 인터넷 출입구가 먼저 생겨야 동작하므로 순서를 강제합니다.
  tags          = { Name = "primary-nat" }
}

# 5-3. 프라이빗 전용 라우팅 테이블(이정표) 생성: "외부 인터넷(0.0.0.0/0)으로 가려면 NAT를 통과해라"
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.primary.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "primary-private-rt" }
}

# 5-4. 이 이정표(라우팅 테이블)를 웹 서버가 있는 프라이빗 서브넷(A, C)에 각각 달아줍니다.
resource "aws_route_table_association" "private_app_az1_rt_assoc" {
  subnet_id      = aws_subnet.private_app_az1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_app_az2_rt_assoc" {
  subnet_id      = aws_subnet.private_app_az2.id
  route_table_id = aws_route_table.private_rt.id
}
# ==========================================
# ★ 추가: 퍼블릭 라우팅 테이블 및 연결 (진짜 인터넷 통로)
# ==========================================
# 1. 인터넷 게이트웨이(IGW)로 향하는 이정표 생성
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.primary.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "primary-public-rt" }
}

# 2. 이정표를 퍼블릭 서브넷 A와 C에 각각 달아주기
resource "aws_route_table_association" "public_az1_rt_assoc" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_az2_rt_assoc" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public_rt.id
}