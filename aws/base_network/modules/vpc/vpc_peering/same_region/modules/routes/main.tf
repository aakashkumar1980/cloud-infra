/**
 * Routes Module
 *
 * Creates bidirectional routes for VPC peering connectivity.
 * Routes must be added to BOTH VPCs for traffic to flow in both directions.
 *
 * Traffic Flow After Routes:
 *   vpc_a (10.0.0.0/24) <---> vpc_b (172.16.0.0/26)
 *
 *   Instance in vpc_a wants to reach instance in vpc_b:
 *   1. Check route table: 172.16.0.0/26 -> pcx-xxx (peering connection)
 *   2. Traffic flows through peering connection
 *   3. Arrives at vpc_b, routed to destination instance
 *
 * Note: aws_route resources don't support Name tags (routes are not
 * standalone resources, they're entries within a route table).
 */

/**
 * Routes in vpc_a -> vpc_b
 *
 * Add route to vpc_b's CIDR in all vpc_a route tables.
 * This tells vpc_a: "To reach 172.16.0.0/26, use the peering connection"
 */
resource "aws_route" "route_vpc_a_to_vpc_b" {
  for_each = toset(var.vpc_a_route_table_ids)

  route_table_id            = each.value
  destination_cidr_block    = var.vpc_b_cidr
  vpc_peering_connection_id = var.peering_connection_id
}

/**
 * Routes in vpc_b -> vpc_a
 *
 * Add route to vpc_a's CIDR in all vpc_b route tables.
 * This tells vpc_b: "To reach 10.0.0.0/24, use the peering connection"
 */
resource "aws_route" "route_vpc_b_to_vpc_a" {
  for_each = toset(var.vpc_b_route_table_ids)

  route_table_id            = each.value
  destination_cidr_block    = var.vpc_a_cidr
  vpc_peering_connection_id = var.peering_connection_id
}
