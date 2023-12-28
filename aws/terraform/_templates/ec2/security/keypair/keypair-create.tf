data "http" "keypair_pubickey" {
  url = "https://raw.githubusercontent.com/aakashkumar1980/apps-configs/main/security/ssh/id_rsa_ec2.pub"
}

resource "aws_key_pair" "keypair" {
  public_key = data.http.keypair_pubickey.body

  key_name = "${var.ns}.keypair"
  tags = {
    "Name" = "${var.ns}.keypair"
  }
}
