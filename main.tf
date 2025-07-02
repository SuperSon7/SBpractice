
# VPC
resource "aws_vpc" "blog_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true # DNS 호스트 이름 활성화
  tags = {
    Name = "blog-vpc"
  }
}

# Subnet
resource "aws_subnet" "blog_subnet" {
  vpc_id                  = aws_vpc.blog_vpc.id
  cidr_block              = "10.0.1.0/24"
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
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.blog_igw.id
  }
  tags = {
    Name = "blog-route-table"
  }
}

# RT와 Subnet 연결
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.blog_subnet.id
  route_table_id = aws_route_table.blog_route_table.id
}

locals {
  github_actions_ips = jsondecode(data.http.github_meta.response_body).actions
  all_ssh_ips        = concat(local.github_actions_ips, [var.my_ip])
}

# SG
resource "aws_security_group" "blog_sg" {
  name        = "blog-security-group"
  description = "Allow HTTP, HTTPS, SSH traffic"
  vpc_id      = aws_vpc.blog_vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.all_ssh_ips
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "blog-sg"
    ManagedBy = "Terraform"
  }
}

resource "aws_instance" "blog_server" {
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = "t2.micro"

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name


  subnet_id              = aws_subnet.blog_subnet.id
  vpc_security_group_ids = [aws_security_group.blog_sg.id]
  key_name               = var.key_name

  #Docker 설치
  user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo yum install -y docker
                sudo systemctl start docker
                sudo systemctl enable docker
                sudo usermod -a -G docker ec2-user

                DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
                sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose
                EOF
  tags = {
    Name = "blog-CD-Server"
  }
}

# EC2에 연결할 IAM 역할을 담는 컨테이너
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-ecr-pull-profile"
  role = "ec2-ecr-pull-role"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["<GitHub OIDC thumbprint>"]
}

resource "aws_iam_role" "github_oidc_role" {
  name = "git"
}

output "instance_public_if" {
  value = aws_instance.blog_server.public_ip
}

