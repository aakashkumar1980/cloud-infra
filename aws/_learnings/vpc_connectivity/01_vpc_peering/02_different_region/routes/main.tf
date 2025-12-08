/**
 * Routes Module - Cross-Region
 *
 * Creates bidirectional routes for cross-region VPC peering connectivity.
 * Routes must be added to BOTH VPCs (in different regions) for traffic
 * to flow in both directions.
 *
 * Traffic Flow After Routes:
 *   vpc_a (10.0.0.0/24) [N. Virginia] <---> vpc_c (192.168.0.0/26) [London]
 *
 *   Instance in vpc_a wants to reach instance in vpc_c:
 *   1. Check route table: 192.168.0.0/26 -> pcx-xxx (peering connection)
 *   2. Traffic flows through peering connection across regions
 *   3. Arrives at vpc_c in London, routed to destination instance
 *
 * Note: aws_route resources don't support Name tags (routes are not
 * standalone resources, they're entries within a route table).
 *
 * Cross-Region Considerations:
 *   - Routes must be created in each region using the appropriate provider
 *   - The peering connection ID is the same on both sides
 */

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.nvirginia, aws.london]
    }
  }
}

/**
 * Routes in vpc_a -> vpc_c (N. Virginia side)
 *
 * Add route to vpc_c's CIDR in all vpc_a route tables.
 * This tells vpc_a: "To reach 192.168.0.0/26, use the peering connection"
 */
resource "aws_route" "route_vpc_a_to_vpc_c" {
  provider = aws.nvirginia
  for_each = toset(var.vpc_a_route_table_ids)

  route_table_id            = each.value
  destination_cidr_block    = var.vpc_c_cidr
  vpc_peering_connection_id = var.peering_connection_id
}

/**
 * Routes in vpc_c -> vpc_a (London side)
 *
 * Add route to vpc_a's CIDR in all vpc_c route tables.
 * This tells vpc_c: "To reach 10.0.0.0/24, use the peering connection"
 */
resource "aws_route" "route_vpc_c_to_vpc_a" {
  provider = aws.london
  for_each = toset(var.vpc_c_route_table_ids)

  route_table_id            = each.value
  destination_cidr_block    = var.vpc_a_cidr
  vpc_peering_connection_id = var.peering_connection_id
}
