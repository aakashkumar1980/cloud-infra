resource "aws_vpc_peering_connection_accepter" "peering_connection-accept" {
  vpc_peering_connection_id = var.peering_id
  auto_accept               = true

  tags = {
    Name = "${var.tag_path}.vpc_peering_remote.${var.entity_name}-accepter"
  }
}
