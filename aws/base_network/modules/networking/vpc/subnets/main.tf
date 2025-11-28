/**
 * Subnets Module
 *
 * Creates subnets within VPCs and sets up networking for internet access.
 *
 * Subnet Types:
 *   - public:  Can access internet directly via Internet Gateway
 *   - private: Can only access internet outbound via NAT Gateway
 *
 * This module also creates:
 *   - NAT Gateways (for private subnet internet access)
 *   - Route Tables (for traffic routing)
 *
 * Naming Convention:
 *   subnet_{tier}_zone_{zone}-{vpc_name}-{region}-{environment}-{managed_by}
 *   Example: subnet_public_zone_a-vpc_a-nvirginia-dev-terraform
 */

/**
 * Subnet Resource
 *
 * Creates subnets from the flattened configuration in locals.tf.
 * Each subnet is placed in a specific availability zone.
 *
 * @for_each local.subnets_flat - Flattened map of all subnets
 * @param vpc_id            - Parent VPC ID
 * @param cidr_block        - IP address range for the subnet
 * @param availability_zone - AZ where the subnet is created
 */
resource "aws_subnet" "this" {
  for_each          = local.subnets_flat
  vpc_id            = var.vpc_ids[each.value.vpc_name]
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.common_tags, {
    Name = "subnet_${each.value.name}-${each.value.vpc_name}-${var.common_tags["region"]}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
  })
}

/**
 * NAT Gateway Module
 *
 * Creates NAT Gateways for VPCs that have private subnets.
 * NAT Gateways allow private subnet resources to access the internet
 * for things like software updates, while remaining unreachable from outside.
 */
module "nat_gateway" {
  source      = "./nat_gateway"
  vpcs        = var.vpcs
  vpc_ids     = var.vpc_ids
  subnet_ids  = { for k, s in aws_subnet.this : k => s.id }
  igw_ids     = var.igw_ids
  igw_names   = var.igw_names
  common_tags = var.common_tags
}

/**
 * Route Tables Module
 *
 * Creates route tables for both public and private subnets:
 *   - Public route tables: Route 0.0.0.0/0 to Internet Gateway
 *   - Private route tables: Route 0.0.0.0/0 to NAT Gateway
 */
module "route_tables" {
  source          = "./route_tables"
  vpcs            = var.vpcs
  vpc_ids         = var.vpc_ids
  igw_ids         = var.igw_ids
  nat_gateway_ids = module.nat_gateway.nat_gateway_ids
  subnet_ids      = { for k, s in aws_subnet.this : k => s.id }
  common_tags     = var.common_tags
}
