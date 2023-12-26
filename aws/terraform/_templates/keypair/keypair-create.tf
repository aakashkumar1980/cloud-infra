resource "aws_key_pair" "keypair" {
  public_key = file("../_templates/keypair/.ssh/id_rsa_ec2.pub")

  key_name = "${var.ns}.keypair"
  tags = {
    "Name" = "${var.ns}.keypair"
  }
}
