/**
 * Public Route Tables Module
 *
 * Creates route tables that allow public subnets to access the internet directly.
 * Each public subnet gets its own route table with a route to the Internet Gateway.
 *
 * How Public Routing Works:
 *   1. Instance in public subnet sends traffic to 8.8.8.8 (Google DNS)
 *   2. Route table checks: Does 8.8.8.8 match VPC CIDR? No.
 *   3. Route table uses 0.0.0.0/0 rule -> send to Internet Gateway
 *   4. Internet Gateway sends traffic to the internet
 *   5. Response comes back through Internet Gateway to the instance
 *
 * Resources Created:
 *   - aws_route_table.public     : The route table itself
 *   - aws_route.public_internet  : The 0.0.0.0/0 -> IGW route
 *   - aws_route_table_association: Links route table to subnet
 *
 * Naming Convention:
 *   routetable-{subnet_name}-{name_suffix}
 *   Example: routetable-subnet_public_zone_a-vpc_a-nvirginia-dev-terraform
 */

/** Create route table for each public subnet */
resource "aws_route_table" "public" {
  for_each = local.public_subnets
  vpc_id   = var.vpc_ids[each.value.vpc_name]

  tags = merge(var.common_tags, {
    Name = "routetable-${each.value.subnet_name}-${var.name_suffix}"
    Tier = each.value.tier
  })
}

/** Add default route to Internet Gateway for internet access */
resource "aws_route" "public_internet" {
  for_each               = local.public_subnets
  route_table_id         = aws_route_table.public[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.igw_ids[each.value.vpc_name]
}

/** Associate route table with its subnet */
resource "aws_route_table_association" "public" {
  for_each       = local.public_subnets
  subnet_id      = var.subnet_ids[each.value.subnet_key]
  route_table_id = aws_route_table.public[each.key].id
}
