/**
 * Peering Connection Module
 *
 * Creates the VPC peering connection between vpc_a (requester) and vpc_b (accepter).
 * Since both VPCs are in the same account and region, we can auto-accept.
 *
 * VPC Peering Characteristics:
 *   - Direct private connectivity between two VPCs
 *   - Non-transitive (if A peers with B and B peers with C, A cannot reach C through B)
 *   - No bandwidth bottleneck (uses AWS backbone)
 *   - No single point of failure
 *   - Free within same region (data transfer charges apply)
 *
 * Naming Convention:
 *   peering-{requester_vpc}-to-{accepter_vpc}-{name_suffix}
 */

resource "aws_vpc_peering_connection" "peering_vpc_a_to_vpc_b" {
  vpc_id      = var.vpc_a_id   # Requester VPC
  peer_vpc_id = var.vpc_b_id   # Accepter VPC
  auto_accept = true           # Auto-accept since same account

  tags = merge(var.common_tags, {
    Name = "peering-vpc_a-to-vpc_b-${var.name_suffix}"
    Side = "Requester"
  })
}
