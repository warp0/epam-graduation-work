variable "aws_region" {
  description = "choose region where to deploy ec2"
  default     = "us-east-2"  
}

variable "key_pair" {
  description  = "desired name of the keypair"
  default      = "keypair1"
}