provider "aws" {
  region = "${var.aws_region}"
}

module "init" {
  source = "init.tf"
}

module "vpc_firewall" {
  source = "vpc_firewall.tf"
}

module "devtools_bastion" {
  source = "devtools_bastion.tf"
}
