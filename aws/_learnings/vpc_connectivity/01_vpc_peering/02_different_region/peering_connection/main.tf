/**
 * Peering Connection Module - Cross-Region
 *
 * Creates the VPC peering connection between vpc_a (requester in N. Virginia)
 * and vpc_c (accepter in London).
 *
 * Cross-Region VPC Peering Characteristics:
 *   - Direct private connectivity between two VPCs in different regions
 *   - Non-transitive (if A peers with B and B peers with C, A cannot reach C through B)
 *   - No bandwidth bottleneck (uses AWS backbone)
 *   - No single point of failure
 *   - Data transfer charges apply (inter-region rates)
 *
 * Key Difference from Same-Region Peering:
 *   - Cannot use auto_accept = true
 *   - Requires separate aws_vpc_peering_connection_accepter resource
 *   - Must specify peer_region in the peering request
 *
 * Naming Convention:
 *   peering-{requester_vpc}-to-{accepter_vpc}-{name_suffix}
 */

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.requester, aws.accepter]
    }
  }
}

/**
 * VPC Peering Connection Request (Requester Side - N. Virginia)
 *
 * Creates the peering request from vpc_a to vpc_c.
 * For cross-region peering, we must specify peer_region.
 */
resource "aws_vpc_peering_connection" "peering_vpc_a_to_vpc_c" {
  provider = aws.requester

  vpc_id      = var.vpc_a_id      # Requester VPC (N. Virginia)
  peer_vpc_id = var.vpc_c_id      # Accepter VPC (London)
  peer_region = var.peer_region   # Required for cross-region peering
  auto_accept = false             # Cannot auto-accept cross-region peering

  tags = merge(var.common_tags, {
    Name = "peering-vpc_a-to-vpc_c-${var.name_suffix}"
    Side = "Requester"
  })
}

/**
 * VPC Peering Connection Accepter (Accepter Side - London)
 *
 * Accepts the peering request in the peer region.
 * This is required for cross-region peering (cannot use auto_accept).
 */
resource "aws_vpc_peering_connection_accepter" "accepter" {
  provider = aws.accepter

  vpc_peering_connection_id = aws_vpc_peering_connection.peering_vpc_a_to_vpc_c.id
  auto_accept               = true

  tags = merge(var.common_tags, {
    Name = "peering-vpc_a-to-vpc_c-${var.name_suffix}"
    Side = "Accepter"
  })
}
