# 프로바이더와 리전 설정
provider "aws" {
    region = region = "ap-northeast-2"
}

# VPC
resource "aws_vpc" "blog_vpc" {
    cidr_block = "10.0.0.0/16"
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
        gateway_id = aws_internet_gateway.my_igw.id
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
    vpc_id = aws_vpx.blog_vpc.id

    ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks =
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


}