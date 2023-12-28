resource "aws_ec2_transit_gateway_peering_attachment" "peering_attachment_requester" {
  peer_account_id         = var.peer_account_id
  peer_region             = var.peer_region
  peer_transit_gateway_id = var.peer_transit_gateway_id

  transit_gateway_id = var.transit_gateway_id

  tags = {
    Name = "${var.tag_path}.tgw_${var.entity_name}.peering_attachment_requester"
  }
}
