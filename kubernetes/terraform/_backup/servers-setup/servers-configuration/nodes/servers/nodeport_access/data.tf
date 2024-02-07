data "aws_network_acls" "selected-nacl" {
  filter {
    name   = "association.subnet-id"
    values = ["${var.subnet_id}"]
  }
}
