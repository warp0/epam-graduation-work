provider "aws" {
  region = "${var.aws_region}"
}

# Starting VPC

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  provisioner "local-exec" {
    command = "openssl genrsa -out key.pem 2048 && openssl rsa -in key.pem -outform PEM -pubout -out public.pem"
  }
} 
resource "aws_key_pair" "deployer" {
  key_name   = "${key_pair}"
  public_key = "${file("public.pem")}"
}

#set subnets for bridged 
resource "aws_subnet" "main_bridge" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.2.0/24"
}

#create gateways for vpc

#create internet gateway
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.main.id}"
}

#set routing table
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }
}
resource "aws_route_table_association" "public" {
  subnet_id = "${aws_subnet.main_bridge.id}"
  route_table_id = "${aws_route_table.public.id}"
}

#create security groups

#allow any inbound and outbound traffic but not expose any port
resource "aws_security_group" "noport" {
  name  = "allow_all"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["${aws_vpc.main.cidr_block}"]
  } 
  
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    self            = true
  }   
  
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

#expose only http
resource "aws_security_group" "webserv" {
  
  name  = "webserv"

  vpc_id = "${aws_vpc.main.id}"
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["${aws_vpc.main.cidr_block}"]
  }
  
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    self            = true
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"] 
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }  
}

#expose only SSH
resource "aws_security_group" "ssh" {
  
  name  = "webserv"

  vpc_id = "${aws_vpc.main.id}"
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["${aws_vpc.main.cidr_block}"]
  }
  
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    self            = true
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"] 
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }  
}



data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

#up devtools instance
resource "aws_instance" "devtools" {
  ami                = "${data.aws_ami.ubuntu.id}"
  instance_type      = "t2.micro"
  key_name           = "${var.key_name}"
  subnet_id          = "${aws_subnet.main_nat.id}"
  vpc_security_group_ids = ["${aws_security_group.noport.id}"]

  tags = {
    Name = "DevTools instance"
  }
}


#up Bastion
resource "aws_instance" "bastion" {
  ami                = "${data.aws_ami.ubuntu.id}"
  instance_type      = "t2.micro"
  key_name           = "${var.key_name}"
  subnet_id          = "${aws_subnet.main_bridge.id}"
  vpc_security_group_ids = ["${aws_security_group.ssh.id}"]

  tags = {
    Name = "Bastion instance"
  }
  provisioner "file" {
    source      = "ansible_install.sh"
    destination = "/var/users/ubuntu"

    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = "${file("privkey.ppk")}"
    }
  }
}

