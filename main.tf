provider "aws" {
  region = "${var.aws_region}"
}

# Starting VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
} 
resource "aws_key_pair" "deployer" {
  key_name   = "${var.key_pair}"
  public_key = "${file("./public.pem")}"
}

#set subnets for bridged 
resource "aws_subnet" "main_bridge" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
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
  name  = "noport"
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
    protocol        = "6"
    cidr_blocks     = ["0.0.0.0/0"] 
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }  
}

resource "aws_security_group" "jenksg" {
  
  name  = "jenksg"

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
    protocol        = "6"
    cidr_blocks     = ["0.0.0.0/0"] 

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "6"
    cidr_blocks     = ["0.0.0.0/0"] 
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }  
}


#expose artifactory
resource "aws_security_group" "artif" {
  
  name  = "artif"

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
    from_port       = 8081
    to_port         = 8081
    protocol        = "6"
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
  
  name  = "ssh"

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
    protocol        = "6"
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
  key_name           = "${var.key_pair}"
  subnet_id          = "${aws_subnet.main_bridge.id}"
  vpc_security_group_ids = ["${aws_security_group.jenksg.id}"]
  associate_public_ip_address = true

  tags = {
    Name = "DevTools instance"
  }
}

resource "aws_instance" "qa" {
  ami                = "${data.aws_ami.ubuntu.id}"
  instance_type      = "t2.micro"
  key_name           = "${var.key_pair}"
  subnet_id          = "${aws_subnet.main_bridge.id}"
  vpc_security_group_ids = ["${aws_security_group.webserv.id}"]
  associate_public_ip_address = true

  tags = {
    Name = "QA instance"
  }
}

resource "aws_instance" "prod" {
  ami                = "${data.aws_ami.ubuntu.id}"
  instance_type      = "t2.micro"
  key_name           = "${var.key_pair}"
  subnet_id          = "${aws_subnet.main_bridge.id}"
  vpc_security_group_ids = ["${aws_security_group.webserv.id}"]
  associate_public_ip_address = true

  tags = {
    Name = "PRODUCTION instance"
  }
}

resource "aws_instance" "artifactory" {
  ami                = "${data.aws_ami.ubuntu.id}"
  instance_type      = "t2.micro"
  key_name           = "${var.key_pair}"
  subnet_id          = "${aws_subnet.main_bridge.id}"
  vpc_security_group_ids = ["${aws_security_group.artif.id}"]
  associate_public_ip_address = true

  tags = {
    Name = "Artifactory instance"
  }
}

#up Bastion
resource "aws_instance" "bastion" {
  ami                = "${data.aws_ami.ubuntu.id}"
  instance_type      = "t2.micro"
  key_name           = "${var.key_pair}"
  subnet_id          = "${aws_subnet.main_bridge.id}"
  vpc_security_group_ids = ["${aws_security_group.ssh.id}"]
  associate_public_ip_address = true

  tags = {
    Name = "Bastion instance"
  }
  
  #preparing inventory
  provisioner "local-exec" {
  command = <<EOT
  
  echo '[jenkins]' > ./ansible/hosts
  echo '${aws_instance.devtools.private_ip} ansible_ssh_private_key_file=./key.pem' >> ./ansible/hosts
  
  echo '[artifactory]' >> ./ansible/hosts
  echo '${aws_instance.artifactory.private_ip} ansible_ssh_private_key_file=./key.pem' >> ./ansible/hosts
  echo 'artifactory_ip: "${aws_instance.artifactory.private_ip}"' > ./ansible/deploy_jar_prod/vars/main.yml
  echo 'artifactory_ip: "${aws_instance.artifactory.private_ip}"' > ./ansible/deploy_jar_qa/vars/main.yml

  echo '[qa]' >> ./ansible/hosts
  echo '${aws_instance.qa.private_ip} ansible_ssh_private_key_file=./key.pem' >> ./ansible/hosts

  echo '[prod]' >> ./ansible/hosts
  echo '${aws_instance.prod.private_ip} ansible_ssh_private_key_file=./key.pem' >> ./ansible/hosts

  echo 'jenkins_dns: "${aws_instance.devtools.public_dns}"' > ./ansible/jenkins_run/vars/main.yml

  EOT
  }


  provisioner "file" {
    connection {
        host     = "${aws_instance.bastion.public_ip}"
        type     = "ssh"
        user     = "ubuntu"
        private_key = "${file("key.pem")}"  
    }
    source      = "./ansible"
    destination = "/home/ubuntu/"
    }
#Installing ansible on bastion
  provisioner "remote-exec" {
    #getting SSH connection
    connection {
      host     = "${aws_instance.bastion.public_ip}"
      type     = "ssh"
      user     = "ubuntu"
      private_key = "${file("key.pem")}"
    }

    #running remotely install commands: installing pip, ansible, exporting private key
    inline = [
              "cd",
              "sudo apt install python -y",
              "sudo wget https://bootstrap.pypa.io/get-pip.py",
              "sudo chmod +x get-pip.py",
              "sudo python get-pip.py",
              "sudo rm get-pip.py",
              "sudo pip install ansible",
              "cd ansible",
              "echo '${file("key.pem")}' > key.pem",
              "chmod 700 key.pem",
              #configuring ansible not to ask for approval of unknown certificate
              "sudo mkdir /etc/ansible",
              "sudo wget -O /etc/ansible/ansible.cfg https://raw.githubusercontent.com/ansible/ansible/devel/examples/ansible.cfg",
              "sudo sed -i 's/#host_key_checking = False/host_key_checking = False/g' /etc/ansible/ansible.cfg",
              #running imported playbook
              "sudo ansible-playbook -i hosts -u ubuntu init.yml"
              ]
  }
}
