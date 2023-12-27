resource "aws_ec2_transit_gateway_route" "transit_gateway_route" {
  destination_cidr_block         = var.cidr_block
  
  transit_gateway_attachment_id  = var.transit_gateway_attachment_id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}
