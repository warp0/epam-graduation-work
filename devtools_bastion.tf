#choose ami image for instance

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
}