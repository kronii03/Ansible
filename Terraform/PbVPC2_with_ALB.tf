# 두번째VPC(Public Network 2개(IGW포함, EC2한대, EC2두대))
# second_vpc.tf

# VPC 생성
resource "aws_vpc" "ELB_VPC" {
  cidr_block = "10.40.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "ELB-VPC"
  }
}

# Public Subnet 생성
resource "aws_subnet" "ELBPublicSN1" {
  vpc_id                  = aws_vpc.ELB_VPC.id
  cidr_block              = "10.40.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "ELB-Public-SN1"
  }
}

# Public Subnet 생성
resource "aws_subnet" "ELBPublicSN2" {
  vpc_id                  = aws_vpc.ELB_VPC.id
  cidr_block              = "10.40.2.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true
  tags = {
    Name = "ELB-Public-SN2"
  }
}

# Internet Gateway 생성
resource "aws_internet_gateway" "ELB_IGW" {
  vpc_id = aws_vpc.ELB_VPC.id
  tags = {
    Name = "ELB-IGW"
  }
}

# Public Route Table 생성
resource "aws_route_table" "ELB_RT" {
  vpc_id = aws_vpc.ELB_VPC.id
  tags = {
    Name = "ELB-Public-RT"
  }
}

# Public Route Table에 인터넷 게이트웨이 연결
resource "aws_route" "Link_ELB_IGW" {
  route_table_id         = aws_route_table.ELB_RT.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ELB_IGW.id
}

# Public Subnet에 Public Route Table 연결
resource "aws_route_table_association" "Link_ELB_RT1" {
  subnet_id      = aws_subnet.ELBPublicSN1.id
  route_table_id = aws_route_table.ELB_RT.id
}


# Public Subnet에 Public Route Table 연결
resource "aws_route_table_association" "Link_ELB_RT2" {
  subnet_id      = aws_subnet.ELBPublicSN2.id
  route_table_id = aws_route_table.ELB_RT.id
}


# Security Group for Public Subnet
resource "aws_security_group" "ELB_SG" {
  vpc_id = aws_vpc.ELB_VPC.id
  name   = "public-sg"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # SSH 접근을 위해 모든 IP 허용
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 161
    to_port     = 161
    protocol    = "udp"
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
resource "aws_instance" "SERVER_1" {
  ami           = "ami-070e986143a3041b6"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.ELBPublicSN1.id
  vpc_security_group_ids = [aws_security_group.ELB_SG.id]
  key_name = "my-default-keypair"
  associate_public_ip_address = true
  tags = {
    Name = "SERVER-1"
  }
}

# EC2 인스턴스 (Private Subnet)
resource "aws_instance" "SERVER_2" {
  ami           = "ami-070e986143a3041b6"  # 예시로 Amazon Linux 2 AMI (리전마다 다를 수 있음)
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.ELBPublicSN2.id
  vpc_security_group_ids = [aws_security_group.ELB_SG.id]
  key_name = "my-default-keypair"
  associate_public_ip_address = true
  tags = {
    Name = "SERVER-2"
  }
}

# EC2 인스턴스 (Private Subnet)
resource "aws_instance" "SERVER_3" {
  ami           = "ami-070e986143a3041b6"  # 예시로 Amazon Linux 2 AMI (리전마다 다를 수 있음)
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.ELBPublicSN2.id
  vpc_security_group_ids = [aws_security_group.ELB_SG.id]
  key_name = "my-default-keypair"
  associate_public_ip_address = true
  tags = {
    Name = "SERVER-3"
  }
}

