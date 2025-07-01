# 프로바이더와 리전 설정
provider "aws" {
    region = "ap-northeast-2"
    profile = "AdministratorAccess-658173955655"
}

# Key Pair
variable "key_name" {
  description = "EC2 instance key pair for SSH access"
  type = string
  default = "blog-keypair"
}

# VPC
resource "aws_vpc" "blog_vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true # DNS 호스트 이름 활성화
    tags = {
        Name = "blog-vpc"
    }
}

# Subnet
resource "aws_subnet" "blog_subnet" {
    vpc_id = aws_vpc.blog_vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true # EC2에 공인 IP 자동 할당
    tags = {
        Name = "blog-subnet"
    }
}

# IG
resource "aws_internet_gateway" "blog_igw" {
    vpc_id = aws_vpc.blog_vpc.id
    tags = {
        Name = "blog-igw"
    }
}

# Route Table
resource "aws_route_table" "blog_route_table" {
    vpc_id = aws_vpc.blog_vpc.id
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.blog_igw.id
    }
    tags = {
        Name = "blog-route-table"
    }
}

# RT와 Subnet 연결
resource "aws_route_table_association" "a" {
    subnet_id = aws_subnet.blog_subnet.id
    route_table_id = aws_route_table.blog_route_table.id
}

# SG
resource "aws_security_group" "blog_sg" {
    name = "blog-security-group"
    description = "Allow HTTP, HTTPS, SSH traffic"
    vpc_id = aws_vpc.blog_vpc.id

    ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks =["221.139.242.217/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

# 최대한 표준적인 이미지 찾기
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "my_server" {
  ami   = data.aws_ami.latest_amazon_linux.id

  instance_type = "t2.micro"
  subnet_id = aws_subnet.blog_subnet.id
  vpc_security_group_ids = [aws_security_group.blog_sg.id]
  key_name = var.key_name

  #Docker 설치
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install docker -y
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo usermod -a -G docker ec2-user
              # Docker Compose 설치
              sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              sudo chmod +x /usr/local/bin/docker-compose
              EOF
  tags = {
    Name = "My-CD-Server"
  }
}

output "instance_public_if" {
  value = aws_instance.my_server.public_ip
}