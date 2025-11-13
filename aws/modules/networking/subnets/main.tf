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
    name   = "${each.value.vpc_name}-${each.value.name}"
    tier   = each.value.tier
    region = var.region
  })
}
