#up ci instance
resource "aws_instance" "ci" {
  ami                = "${data.aws_ami.ubuntu.id}"
  instance_type      = "t2.micro"
  key_name           = "${var.key_name}"
  subnet_id          = "${aws_subnet.main_bridge.id}"
  vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]

  tags = {
    Name = "Continious Integration"
  }
}
#up qa instance
resource "aws_instance" "qa" {
  ami                = "${data.aws_ami.ubuntu.id}"
  instance_type      = "t2.micro"
  key_name           = "${var.key_name}"
  subnet_id          = "${aws_subnet.main_bridge.id}"
  vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]

  tags = {
    Name = "Quality Assurance"
  }
}

#up Docker instance
resource "aws_instance" "docker" {
  ami                = "${data.aws_ami.ubuntu.id}"
  instance_type      = "t2.micro"
  key_name           = "${var.key_name}"
  subnet_id          = "${aws_subnet.main_bridge.id}"
  vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]

  tags = {
    Name = "Docker Deployment"
  }
}