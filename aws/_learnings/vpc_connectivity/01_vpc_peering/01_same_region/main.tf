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
 * Peering Connection Module
 *
 * Creates the VPC peering connection between vpc_a (requester) and vpc_b (accepter).
 */
module "peering_connection" {
  source = "./peering_connection"

  vpc_a_id    = data.aws_vpc.vpc_a.id
  vpc_b_id    = data.aws_vpc.vpc_b.id
  common_tags = local.tags_common
  name_suffix = local.name_suffix_nvirginia
}

/**
 * Routes Module
 *
 * Creates bidirectional routes in both VPCs to enable traffic flow
 * through the peering connection.
 */
module "routes" {
  source = "./routes"

  vpc_a_cidr            = data.aws_vpc.vpc_a.cidr_block
  vpc_b_cidr            = data.aws_vpc.vpc_b.cidr_block
  vpc_a_route_table_ids = [for rt in data.aws_route_table.vpc_a : rt.id]
  vpc_b_route_table_ids = [for rt in data.aws_route_table.vpc_b : rt.id]
  peering_connection_id = module.peering_connection.peering_connection_id
}

/**
 * Test Module (Optional)
 *
 * Creates EC2 instances to validate VPC peering connectivity.
 * Set enable_test = true to create test resources.
 */
module "test" {
  count  = var.enable_test ? 1 : 0
  source = "./_test"

  vpc_a_id    = data.aws_vpc.vpc_a.id
  vpc_b_id    = data.aws_vpc.vpc_b.id
  vpc_a_cidr  = data.aws_vpc.vpc_a.cidr_block
  vpc_b_cidr  = data.aws_vpc.vpc_b.cidr_block
  name_suffix = local.name_suffix_nvirginia
  key_name    = var.key_name
  my_ip       = var.my_ip

  depends_on = [module.routes]
}
