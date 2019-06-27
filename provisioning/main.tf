
#preparing inventory

provisioner "local-exec" {

  comand = "echo ${aws_instance.devtools.private_ip} >> hosts"
  #comand = "echo ${aws_instance.ci.private_ip} >> hosts"
  #comand = "echo ${aws_instance.qa.private_ip} >> hosts"
  #comand = "echo ${aws_instance.docker.private_ip} >> hosts"
}



#Installing ansible on bastion
provisioner "remote-exec" {
  
  connection {
    host     = "${aws_instance.bastion.public_ip}"
    type     = "ssh"
    user     = "ubuntu"
    private_key = "${file("key.pem")}"
  }

  inline = [
            "cd",
            "sudo apt install python -y",
            "sudo wget https://bootstrap.pypa.io/get-pip.py",
            "sudo chmod +x get-pip.py",
            "sudo python get-pip.py",
            "sudo rm get-pip.py",
            "sudo pip install ansible",
            ]
}

#providing identity key to manage infrastucture