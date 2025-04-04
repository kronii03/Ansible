# 첫번째VPC(Public Network 1개(IGW포함, EC2한대))
# first_vpc.tf

# VPC 생성
resource "aws_vpc" "main" {
  cidr_block = "20.40.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "MY-VPC"
  }
}

# Public Subnet 생성
resource "aws_subnet" "MyPublicSN" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "20.40.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "MY-Public-SN"
  }
}

# Internet Gateway 생성
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "MY-IGW"
  }
}

# Public Route Table 생성
resource "aws_route_table" "MyRT" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "MY-Public-RT"
  }
}

# Public Route Table에 인터넷 게이트웨이 연결
resource "aws_route" "internet1" {
  route_table_id         = aws_route_table.MyRT.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.IGW.id
}

# Public Subnet에 Public Route Table 연결
resource "aws_route_table_association" "LinkToSN" {
  subnet_id      = aws_subnet.MyPublicSN.id
  route_table_id = aws_route_table.MyRT.id
}

# Security Group for Public Subnet
resource "aws_security_group" "MySG" {
  vpc_id = aws_vpc.main.id
  name   = "MySG"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 인스턴스 (Public Subnet)
resource "aws_instance" "MyEC2" {
  ami           = "ami-070e986143a3041b6"  # 예시로 Amazon Linux 2 AMI (리전마다 다를 수 있음)
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.MyPublicSN.id
  vpc_security_group_ids = [aws_security_group.MySG.id]
  key_name   = "my-default-keypair"
  tags = {
    Name = "MY-EC2"
  }
}
