/**
 * VPC Peering - Cross-Region (Different Region)
 *
 * Creates a VPC peering connection between vpc_a (N. Virginia) and vpc_c (London).
 *
 * Cross-Region VPC Peering Characteristics:
 *   - Direct private connectivity between two VPCs in different regions
 *   - Non-transitive (if A peers with B and B peers with C, A cannot reach C through B)
 *   - No bandwidth bottleneck (uses AWS backbone)
 *   - No single point of failure
 *   - Data transfer charges apply (inter-region rates)
 *   - Cannot auto-accept (requires explicit accepter in peer region)
 *
 * Requirements:
 *   - VPC CIDR ranges must not overlap
 *   - Peering request must be explicitly accepted in the accepter region
 *   - Route tables must be updated in both VPCs (both regions)
 *
 * Traffic Flow After Peering:
 *   vpc_a (10.0.0.0/24) [N. Virginia] <---> vpc_c (192.168.0.0/26) [London]
 *
 *   Instance in vpc_a wants to reach instance in vpc_c:
 *   1. Check route table: 192.168.0.0/26 -> pcx-xxx (peering connection)
 *   2. Traffic flows through peering connection across regions
 *   3. Arrives at vpc_c in London, routed to destination instance
 */

/**
 * Peering Connection Module
 *
 * Creates the VPC peering connection between vpc_a (requester in N. Virginia)
 * and vpc_c (accepter in London).
 *
 * For cross-region peering:
 *   - The requester creates the peering request
 *   - The accepter must explicitly accept the request (no auto_accept)
 */
module "peering_connection" {
  source = "./peering_connection"

  providers = {
    aws.requester = aws.nvirginia
    aws.accepter  = aws.london
  }

  vpc_a_id         = data.aws_vpc.vpc_a.id
  vpc_c_id         = data.aws_vpc.vpc_c.id
  peer_region      = local.regions_cfg[local.REGION_LONDON]
  tags_common      = local.tags_common
  name_suffix      = "${local.REGION_N_VIRGINIA}-to-${local.REGION_LONDON}-${var.profile}-${local.tags_common["managed_by"]}"
}

/**
 * Routes Module
 *
 * Creates bidirectional routes in both VPCs to enable traffic flow
 * through the peering connection across regions.
 */
module "routes" {
  source = "./routes"

  providers = {
    aws.nvirginia = aws.nvirginia
    aws.london    = aws.london
  }

  vpc_a_cidr            = data.aws_vpc.vpc_a.cidr_block
  vpc_c_cidr            = data.aws_vpc.vpc_c.cidr_block
  vpc_a_route_table_ids = [for rt in data.aws_route_table.vpc_a : rt.id]
  vpc_c_route_table_ids = [for rt in data.aws_route_table.vpc_c : rt.id]
  peering_connection_id = module.peering_connection.peering_connection_id
}

/**
 * Test Module (Optional)
 *
 * Creates EC2 instances to validate cross-region VPC peering connectivity:
 *   1. Bastion (vpc_a public subnet, N. Virginia) - Jump host with public IP
 *   2. VPC A Private Instance (N. Virginia)       - Target in same VPC
 *   3. VPC C Private Instance (London)            - Target in peered VPC (different region)
 *
 * Set enable_test = true to create test resources.
 */
module "test" {
  count  = var.enable_test ? 1 : 0
  source = "./_test"

  providers = {
    aws.nvirginia = aws.nvirginia
    aws.london    = aws.london
  }

  vpc_a_id             = data.aws_vpc.vpc_a.id
  vpc_c_id             = data.aws_vpc.vpc_c.id
  vpc_a_cidr           = data.aws_vpc.vpc_a.cidr_block
  vpc_c_cidr           = data.aws_vpc.vpc_c.cidr_block
  name_suffix_nvirginia = local.name_suffix_nvirginia
  name_suffix_london    = local.name_suffix_london

  # Configuration paths
  config_path          = "${local.env_dir}/amis.yaml"
  common_firewall_path = "${local.config_dir}/firewall.yaml"

  depends_on = [module.routes]
}
