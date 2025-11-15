resource "aws_network_acl" "nacl" {
  vpc_id = var.vpc_id

  subnet_ids = var.subnet_ids
  tags = {
    "Name" = "${var.tag_path}.${var.entity_name}"
  }
}
