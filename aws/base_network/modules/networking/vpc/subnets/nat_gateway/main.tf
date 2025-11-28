# NAT Gateway Module
# Creates NAT Gateways for private subnet outbound internet access
# Placed in the first public subnet of each VPC that needs one
#
# Naming: natgw-subnet_{subnet_name}-{region}-{environment}-{managed_by}
# Example: natgw-subnet_public_zone_a-vpc_a-nvirginia-dev-terraform

# Elastic IP for NAT Gateway (static public IP)
resource "aws_eip" "nat" {
  for_each = local.nat_gateway_subnets
  domain   = "vpc"

  tags = merge(var.common_tags, {
    Name = "eip-natgw-subnet_${local.public_subnets[each.value].subnet_name}-${var.region}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
  })
}

# NAT Gateway (one per VPC, placed in public subnet)
resource "aws_nat_gateway" "this" {
  for_each      = local.nat_gateway_subnets
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = var.subnet_ids[each.value]

  tags = merge(var.common_tags, {
    Name = "natgw-subnet_${local.public_subnets[each.value].subnet_name}-${var.region}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
  })

  depends_on = [var.igw_ids]
}
