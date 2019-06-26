provider "aws" {
  region = "${var.aws_region}"
}

module "init" {
  source = "./"
}

module "vpc_firewall" {
  source = "./"
}

module "devtools_bastion" {
  source = "./"
}
