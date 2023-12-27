resource "aws_ec2_transit_gateway_peering_attachment_accepter" "transit_gateway_peering_attachment_accepter" {
  transit_gateway_attachment_id = var.transit_gateway_attachment_id

  tags = {
    Name = "${var.tag_path}.tgw_${var.entity_name}.peering_attachment_accepter"
  }
}
