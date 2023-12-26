resource "aws_route" "add-igw" {
  route_table_id = var.rt_id

  destination_cidr_block = var.destination_cidr_block
  gateway_id             = var.igw_id
}
