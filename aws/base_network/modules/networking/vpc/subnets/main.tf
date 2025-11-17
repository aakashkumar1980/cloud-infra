/**
 * Subnet creation
 *
 * - flattens var.vpcs[*].subnets into one map
 * - resolves AZ letters into AZ names
 * - attaches to correct VPC by name
 * - tags include tier for future routing logic
 */
resource "aws_subnet" "this" {
  for_each          = local.subnets_flat

  vpc_id            = var.vpc_ids[each.value.vpc_name]
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.common_tags, {
    Name   = "subnet_${each.value.name}-${each.value.vpc_name}-${var.region}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
  })
}

/**
 * Module to create Route Tables for Public Subnets and assign Internet Gateway routes
 */
module "route_tables_public" {
  source      = "./route_tables/public_subnets"
  vpcs        = var.vpcs
  vpc_ids     = var.vpc_ids
  igw_ids     = var.igw_ids
  subnet_ids  = { for k, s in aws_subnet.this : k => s.id }
  common_tags = var.common_tags
  region      = var.region
}
