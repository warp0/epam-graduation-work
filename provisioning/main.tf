provisioner "file" {
  source      = "ansible_install.sh"
  destination = "/var/users/ubuntu"

  connection {
    type     = "ssh"
    user     = "ubuntu"
    private_key = "${file("privkey.ppk")}"
  }
}