resource "aws_vpc_peering_connection" "peering_connection-request" {
  vpc_id      = var.vpc_id
  peer_vpc_id = var.peer_vpc_id
  peer_region = var.peer_region
  auto_accept = false

  timeouts {
    create = "20m"
    delete = "20m"
  }
  tags = {
    Name = "${var.tag_path}.peering_${var.entity_name}-requester"
  }
}
