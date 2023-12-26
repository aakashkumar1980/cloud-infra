resource "aws_network_interface" "eni" {
  source_dest_check = var.source_dest_check
  subnet_id         = var.subnet_id
  security_groups   = var.security_groups

  tags = tomap({
    "Name" = "${var.tag_path}.eni_${var.entity_name}"
  })
}
