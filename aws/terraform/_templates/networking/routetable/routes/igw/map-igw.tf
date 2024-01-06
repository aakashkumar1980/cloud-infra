resource "aws_route" "map-igw" {
  route_table_id = var.rt_id

  destination_cidr_block = var.destination_cidr_block
  gateway_id             = var.igw_id
}
