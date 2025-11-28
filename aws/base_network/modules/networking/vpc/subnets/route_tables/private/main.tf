# Private Route Tables Module
# Routes private subnet traffic to NAT Gateway for outbound-only internet access
#
# Naming: routetable-{subnet_name}-{region}-{environment}-{managed_by}
# Example: routetable-subnet_private_zone_b-vpc_c-london-dev-terraform

# Create route table for each private subnet (only if VPC has NAT Gateway)
resource "aws_route_table" "private" {
  for_each = local.private_subnets
  vpc_id   = var.vpc_ids[each.value.vpc_name]

  tags = merge(var.common_tags, {
    Name = "routetable-${each.value.subnet_name}-${var.region}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
    Tier = each.value.tier
  })
}

# Add default route to NAT Gateway
resource "aws_route" "private_internet" {
  for_each               = local.private_subnets
  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.nat_gateway_ids[each.value.vpc_name]
}

# Associate route table with subnet
resource "aws_route_table_association" "private" {
  for_each       = local.private_subnets
  subnet_id      = var.subnet_ids[each.value.subnet_key]
  route_table_id = aws_route_table.private[each.key].id
}
