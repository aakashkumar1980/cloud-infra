/**
 * Private Route Tables Module
 *
 * Creates route tables that allow private subnets to access the internet
 * for outbound connections only (through NAT Gateway).
 *
 * How Private Routing Works:
 *   1. Instance in private subnet sends traffic to 8.8.8.8 (Google DNS)
 *   2. Route table checks: Does 8.8.8.8 match VPC CIDR? No.
 *   3. Route table uses 0.0.0.0/0 rule -> send to NAT Gateway
 *   4. NAT Gateway (in public subnet) forwards to Internet Gateway
 *   5. Response comes back through NAT Gateway to the instance
 *   6. External servers only see the NAT Gateway's public IP
 *
 * Key Difference from Public:
 *   - Private instances can INITIATE connections to internet
 *   - But internet cannot INITIATE connections to private instances
 *   - This provides an extra layer of security for backend services
 *
 * Resources Created:
 *   - aws_route_table.private     : The route table itself
 *   - aws_route.private_internet  : The 0.0.0.0/0 -> NAT GW route
 *   - aws_route_table_association : Links route table to subnet
 *
 * Note: Private route tables are only created for VPCs that have NAT Gateways.
 *
 * Naming Convention:
 *   routetable-{subnet_name}-{region}-{environment}-{managed_by}
 *   Example: routetable-subnet_private_zone_b-vpc_c-london-dev-terraform
 */

/** Create route table for each private subnet (only if VPC has NAT Gateway) */
resource "aws_route_table" "private" {
  for_each = local.private_subnets
  vpc_id   = var.vpc_ids[each.value.vpc_name]

  tags = merge(var.common_tags, {
    Name = "routetable-${each.value.subnet_name}-${var.region}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
    Tier = each.value.tier
  })
}

/** Add default route to NAT Gateway for outbound internet access */
resource "aws_route" "private_internet" {
  for_each               = local.private_subnets
  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.nat_gateway_ids[each.value.vpc_name]
}

/** Associate route table with its subnet */
resource "aws_route_table_association" "private" {
  for_each       = local.private_subnets
  subnet_id      = var.subnet_ids[each.value.subnet_key]
  route_table_id = aws_route_table.private[each.key].id
}
