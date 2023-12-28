resource "aws_route" "map-ec2_instance" {
  route_table_id = var.route_table_id

  destination_cidr_block = var.destination_cidr_block
  instance_id            = var.instance_id

}
