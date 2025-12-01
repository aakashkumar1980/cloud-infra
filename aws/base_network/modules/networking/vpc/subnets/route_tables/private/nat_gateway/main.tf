/**
 * NAT Gateway Module
 *
 * Creates NAT Gateways to allow private subnet resources to access the internet
 * for outbound connections only (e.g., downloading updates, calling APIs).
 *
 * How it works:
 *   - NAT Gateway sits in a public subnet with an Elastic IP
 *   - Private subnets route 0.0.0.0/0 traffic to the NAT Gateway
 *   - NAT Gateway forwards traffic to Internet Gateway
 *   - Return traffic comes back through NAT Gateway to private subnet
 *
 * Placement:
 *   - One NAT Gateway per VPC (placed in first public subnet)
 *   - Only created for VPCs defined in nat_gateway_vpcs
 *
 * Naming Convention:
 *   natgw-subnet_{subnet_name}-{name_suffix}
 *   Example: natgw-subnet_public_zone_a-vpc_a-nvirginia-dev-terraform
 */

/**
 * Elastic IP for NAT Gateway
 *
 * Each NAT Gateway needs a static public IP address (Elastic IP).
 * This ensures outbound traffic from private subnets always comes
 * from the same IP address.
 *
 * @for_each local.nat_gateway_subnets - One EIP per NAT Gateway
 */
resource "aws_eip" "eip" {
  for_each = local.nat_gateway_subnets
  domain   = "vpc"

  tags = merge(var.common_tags, {
    Name = "eip-natgw-${local.public_subnets[each.value].subnet_name}-${var.name_suffix}"
  })
}

/**
 * NAT Gateway Resource
 *
 * Creates the NAT Gateway in a public subnet.
 * Must wait for Internet Gateway to exist (depends_on).
 *
 * @for_each local.nat_gateway_subnets - One NAT Gateway per VPC
 * @param allocation_id - Elastic IP to associate
 * @param subnet_id     - Public subnet where NAT Gateway is placed
 */
resource "aws_nat_gateway" "this" {
  for_each      = local.nat_gateway_subnets
  allocation_id = aws_eip.eip[each.key].id
  subnet_id     = var.public_subnet_ids[each.value]

  tags = merge(var.common_tags, {
    Name = "natgw-${local.public_subnets[each.value].subnet_name}-${var.name_suffix}"
  })

  depends_on = [var.igw_ids]
}
