resource "aws_vpc_peering_connection" "peering_connection" {
  vpc_id      = var.vpc_id
  peer_vpc_id = var.peer_vpc_id
  auto_accept = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags = {
    Name = "${var.tag_path}.peering_${var.entity_name}"
  }
}
