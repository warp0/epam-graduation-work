provisioner "local-exec" {
    command = "openssl genrsa -out key.pem 2048 && openssl rsa -in key.pem -outform PEM -pubout -out public.pem"
}

resource "aws_key_pair" "deployer" {
  key_name   = "${key_pair}"
  public_key = "${file("public.pem")}"
}