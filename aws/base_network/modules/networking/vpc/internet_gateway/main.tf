# Internet Gateway Module
# Creates one IGW per VPC for public internet access
#
# Naming: igw-{vpc_name}-{region}-{environment}-{managed_by}
# Example: igw-vpc_a-nvirginia-dev-terraform

resource "aws_internet_gateway" "this" {
  for_each = var.vpcs
  vpc_id   = var.vpc_ids[each.key]

  tags = merge(var.common_tags, {
    Name = "igw-${each.key}-${var.region}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
  })
}
