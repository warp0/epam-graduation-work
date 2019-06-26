# Starting VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

#set subnets for bride and NAT
#nat
resource "aws_subnet" "main_nat" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/24"
}
#bridge
resource "aws_subnet" "main_bridge" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.2.0/24"
}

#create gateways for vpc
#get eip for nat gateway
resource "aws_eip" "nat_eip" {
  vpc        = true  
}


#create nat gateway
resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${aws_subnet.main_nat.id}"
}

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

#allow any inbound and outbound traffic (used with NAT subnet and bastion instance)
resource "aws_security_group" "allow_all" {
  name  = "allow_all"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    from_port       = 0
    to_port         = 0
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

#for webservices
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

#for bastion (ssh)
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
