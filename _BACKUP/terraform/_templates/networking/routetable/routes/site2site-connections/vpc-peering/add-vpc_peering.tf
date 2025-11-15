resource "aws_route" "add-vpc_peering" {
  route_table_id = var.routetable_id

  destination_cidr_block    = var.destination_cidr_block
  vpc_peering_connection_id = var.peering_id
}
