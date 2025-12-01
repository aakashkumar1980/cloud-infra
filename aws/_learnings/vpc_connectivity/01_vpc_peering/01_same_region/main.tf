/**
 * VPC Peering - Same Region
 *
 * Creates a VPC peering connection between vpc_a and vpc_b in N. Virginia.
 *
 * VPC Peering Characteristics:
 *   - Direct private connectivity between two VPCs
 *   - Non-transitive (if A peers with B and B peers with C, A cannot reach C through B)
 *   - No bandwidth bottleneck (uses AWS backbone)
 *   - No single point of failure
 *   - Free within same region (data transfer charges apply)
 *
 * Requirements:
 *   - VPC CIDR ranges must not overlap
 *   - Both VPCs must be in the same region (for same-region peering)
 *   - Route tables must be updated in both VPCs
 *
 * Traffic Flow After Peering:
 *   vpc_a (10.0.0.0/24) <---> vpc_b (172.16.0.0/26)
 *
 *   Instance in vpc_a wants to reach instance in vpc_b:
 *   1. Check route table: 172.16.0.0/26 -> pcx-xxx (peering connection)
 *   2. Traffic flows through peering connection
 *   3. Arrives at vpc_b, routed to destination instance
 */

/**
 * VPC Peering Connection
 *
 * Creates the peering connection between vpc_a (requester) and vpc_b (accepter).
 * Since both VPCs are in the same account and region, we can auto-accept.
 */
resource "aws_vpc_peering_connection" "vpc_a_to_vpc_b" {
  vpc_id      = data.aws_vpc.vpc_a.id  # Requester VPC
  peer_vpc_id = data.aws_vpc.vpc_b.id  # Accepter VPC
  auto_accept = true                    # Auto-accept since same account

  tags = {
    Name = "peering-vpc_a-to-vpc_b-${var.name_suffix}"
    Side = "Requester"
  }
}

/**
 * Routes in vpc_a -> vpc_b
 *
 * Add route to vpc_b's CIDR in all vpc_a route tables.
 * This tells vpc_a: "To reach 172.16.0.0/26, use the peering connection"
 */
resource "aws_route" "vpc_a_to_vpc_b" {
  for_each = toset(data.aws_route_tables.vpc_a.ids)

  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.vpc_b.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_a_to_vpc_b.id
}

/**
 * Routes in vpc_b -> vpc_a
 *
 * Add route to vpc_a's CIDR in all vpc_b route tables.
 * This tells vpc_b: "To reach 10.0.0.0/24, use the peering connection"
 */
resource "aws_route" "vpc_b_to_vpc_a" {
  for_each = toset(data.aws_route_tables.vpc_b.ids)

  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.vpc_a.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_a_to_vpc_b.id
}

/**
 * Test Module (Optional)
 *
 * Creates EC2 instances to validate VPC peering connectivity.
 * Set enable_test = true to create test resources.
 */
module "test" {
  count  = var.enable_test ? 1 : 0
  source = "./test"

  vpc_a_id    = data.aws_vpc.vpc_a.id
  vpc_b_id    = data.aws_vpc.vpc_b.id
  vpc_a_cidr  = data.aws_vpc.vpc_a.cidr_block
  vpc_b_cidr  = data.aws_vpc.vpc_b.cidr_block
  name_suffix = var.name_suffix
  key_name    = var.key_name
  my_ip       = var.my_ip

  depends_on = [
    aws_route.vpc_a_to_vpc_b,
    aws_route.vpc_b_to_vpc_a
  ]
}
