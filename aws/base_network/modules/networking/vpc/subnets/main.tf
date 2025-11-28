# Subnets Module
# Creates subnets across availability zones with NAT gateways and route tables
#
# Subnet types:
#   - public: Has route to Internet Gateway (internet accessible)
#   - private: Uses NAT Gateway for outbound-only internet access
#
# Naming: subnet_{tier}_zone_{zone}-{vpc_name}-{region}-{environment}-{managed_by}
# Example: subnet_public_zone_a-vpc_a-nvirginia-dev-terraform

# Create subnets from flattened config
resource "aws_subnet" "this" {
  for_each          = local.subnets_flat
  vpc_id            = var.vpc_ids[each.value.vpc_name]
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.common_tags, {
    Name = "subnet_${each.value.name}-${each.value.vpc_name}-${var.region}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
  })
}

# Create NAT Gateways for private subnet internet access
module "nat_gateway" {
  source      = "./nat_gateway"
  vpcs        = var.vpcs
  vpc_ids     = var.vpc_ids
  subnet_ids  = { for k, s in aws_subnet.this : k => s.id }
  igw_ids     = var.igw_ids
  igw_names   = var.igw_names
  common_tags = var.common_tags
  region      = var.region
}

# Create route tables for public and private subnets
module "route_tables" {
  source          = "./route_tables"
  vpcs            = var.vpcs
  vpc_ids         = var.vpc_ids
  igw_ids         = var.igw_ids
  nat_gateway_ids = module.nat_gateway.nat_gateway_ids
  subnet_ids      = { for k, s in aws_subnet.this : k => s.id }
  common_tags     = var.common_tags
  region          = var.region
}
