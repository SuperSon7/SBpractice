# git-IP
data "http" "github_meta" {
  url = "https://api.github.com/meta"
}

#EC2
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  # 최대한 표준적인 이미지 찾기
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}