resource "aws_vpc_peering_connection_accepter" "peering_connection-accept" {
  vpc_peering_connection_id = var.peering_id
  auto_accept               = true

  timeouts {
    create = "20m"
  }
  tags = {
    Name = "${var.tag_path}.peering_${var.entity_name}-accepter"
  }
}
