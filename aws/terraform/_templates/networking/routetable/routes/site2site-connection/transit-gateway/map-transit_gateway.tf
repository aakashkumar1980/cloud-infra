resource "aws_route" "map-transit_gateway" {
  route_table_id = var.routetable_id

  destination_cidr_block = var.destination_cidr_block
  transit_gateway_id     = var.transit_gateway_id
}
