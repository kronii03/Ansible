
# VPC 생성
resource "aws_vpc" "main1" {
  cidr_block = "10.40.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "ELB-VPC"
  }
}


# Public Subnet 생성
resource "aws_subnet" "public1" {
  vpc_id = aws_vpc.main1.id
  cidr_block = "10.40.1.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "ELBPublicSN1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id = aws_vpc.main1.id
  cidr_block = "10.40.2.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "ELBPublicSN2"
  }
}



# Internet Gateway 생성
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.main1.id
  tags = {
    Name = "ELB-IGW"
  }
}


# Public Route Table 생성
resource "aws_route_table" "public_RT" {
  vpc_id = aws_vpc.main1.id
  tags = {
    Name = "ELBPublicRT"
  }
}


# Public Route Table에 인터넷 게이트웨이 연결
resource "aws_route" "public_IGW" {
  route_table_id = aws_route_table.public_RT.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.IGW.id
}

# Public Subnet에 명시적으로 Public Route Table 연결
resource "aws_route_table_association" "public_rt_assoc1" {
  subnet_id = aws_subnet.public1.id
  route_table_id = aws_route_table.public_RT.id
}

resource "aws_route_table_association" "public_rt_assoc2" {
  subnet_id = aws_subnet.public2.id
  route_table_id = aws_route_table.public_RT.id
}


# Security Group for Public Subnet
resource "aws_security_group" "public_SG" {
  vpc_id = aws_vpc.main1.id
  name = "ELBSG"
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
  ingress {
    description = "Allow HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow UDP 161"
    from_port = 161
    to_port = 161
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# NACL 생성 (Public Subnet용)
resource "aws_network_acl" "public_acl1" {
  vpc_id = aws_vpc.main1.id
  tags = {
    Name = "ELBNACL"
  }
}

# NACL 규칙 추가 (Public Subnet용)
resource "aws_network_acl_rule" "public_acl1_allow_inbound" {
  network_acl_id = aws_network_acl.public_acl1.id
  rule_number = 100
  egress = false
  protocol = -1
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 0
  to_port = 65535
}

resource "aws_network_acl_rule" "public_acl1_allow_outbound" {
  network_acl_id = aws_network_acl.public_acl1.id
  rule_number = 100
  egress = true
  protocol = -1
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 0
  to_port = 65535
}


# EC2 인스턴스 (Public Subnet)
resource "aws_instance" "Ser-1" {
  ami = "ami-070e986143a3041b6" # 예시로 Amazon Linux 2 AMI (리전마다 다를 수 있음)
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public1.id
  vpc_security_group_ids = [aws_security_group.public_SG.id]
  key_name = "my-default-keypair" # key pair 이름 지정
  associate_public_ip_address = true
  tags = {
    Name = "SERVER-1"
  }
}

resource "aws_instance" "Ser-2" {
  ami = "ami-070e986143a3041b6" 
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public2.id
  vpc_security_group_ids = [aws_security_group.public_SG.id]
  key_name = "my-default-keypair" # key pair 이름 지정
  associate_public_ip_address = true
  tags = {
    Name = "SERVER-2"
  }
}

resource "aws_instance" "Ser-3" {
  ami = "ami-070e986143a3041b6"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public2.id
  vpc_security_group_ids = [aws_security_group.public_SG.id]
  key_name = "my-default-keypair" # key pair 이름 지정
  associate_public_ip_address = true
  tags = {
    Name = "SERVER-3"
  }
}


