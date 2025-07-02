# Key Pair
variable "key_name" {
  description = "EC2 instance key pair for SSH access"
  type        = string
  default     = "blog-keypair"
}

variable "my_ip" {
  description = "MY PC for SSH access"
  type        = string
  default     = "221.139.242.217/32"
}