terraform {
  required_version = ">= 1.5.0" # 최소 Terraform 버전 1.5.0 이상
}

# VPC 생성
resource "aws_vpc" "main" {
  cidr_block = "20.40.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "MyVPC"
  }
}

# Public Subnet 생성
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "20.40.1.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "My-Public-SN"
  }
}

# Internet Gateway 생성
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "My-IGW"
  }
}

# Public Route Table 생성
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "MyPublicRT"
  }
}

# Public Route Table에 인터넷 게이트웨이 연결
resource "aws_route" "public_igw" {
  route_table_id = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

# Public Subnet에 명시적으로 Public Route Table 연결
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group for Public Subnet
resource "aws_security_group" "public_sg" {
  vpc_id = aws_vpc.main.id
  name = "MySG"
  ingress {
    description = "Allow ICMP"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"] # SSH 접근을 위해 모든 IP 허용
  }
  ingress {
    description = "Allow SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # SSH 접근을 위해 모든 IP 허용
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# NACL 생성 (Public Subnet용)
resource "aws_network_acl" "public_acl" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "MyNACL"
  }
}

# NACL 규칙 추가 (Public Subnet용)
resource "aws_network_acl_rule" "public_acl_allow_inbound" {
  network_acl_id = aws_network_acl.public_acl.id
  rule_number = 100
  egress = false
  protocol = -1
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 0
  to_port = 65535
}

resource "aws_network_acl_rule" "public_acl_allow_outbound" {
  network_acl_id = aws_network_acl.public_acl.id
  rule_number = 100
  egress = true
  protocol = -1
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 0
  to_port = 65535
}


# EC2 인스턴스 (Public Subnet)
resource "aws_instance" "public_ec2" {
  ami = "ami-070e986143a3041b6" # 예시로 Amazon Linux 2 AMI (리전마다 다를 수 있음)
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  key_name = "my-default-keypair" # key pair 이름 지정
  associate_public_ip_address = true
  tags = {
    Name = "MyEC2"
  }
}
