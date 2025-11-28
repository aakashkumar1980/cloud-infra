# Public Route Tables Module
# Routes public subnet traffic to Internet Gateway for direct internet access
#
# Naming: routetable-{subnet_name}-{region}-{environment}-{managed_by}
# Example: routetable-subnet_public_zone_a-vpc_a-nvirginia-dev-terraform

# Create route table for each public subnet
resource "aws_route_table" "public" {
  for_each = local.public_subnets
  vpc_id   = var.vpc_ids[each.value.vpc_name]

  tags = merge(var.common_tags, {
    Name = "routetable-${each.value.subnet_name}-${var.region}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
    Tier = each.value.tier
  })
}

# Add default route to Internet Gateway
resource "aws_route" "public_internet" {
  for_each               = local.public_subnets
  route_table_id         = aws_route_table.public[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.igw_ids[each.value.vpc_name]
}

# Associate route table with subnet
resource "aws_route_table_association" "public" {
  for_each       = local.public_subnets
  subnet_id      = var.subnet_ids[each.value.subnet_key]
  route_table_id = aws_route_table.public[each.key].id
}
