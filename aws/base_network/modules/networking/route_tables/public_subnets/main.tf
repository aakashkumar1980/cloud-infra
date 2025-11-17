/** *********** **/
/** ROUTE TABLE **/
/** *********** **/
/**
 * Route Table creation for public subnets
 *
 * - one route table per public subnet
 * - includes default route to Internet Gateway
 * - automatically associated with corresponding subnet
 */
resource "aws_route_table" "public" {
  for_each = local.public_subnets

  vpc_id = var.vpc_ids[each.value.vpc_name]
  tags = merge(var.common_tags, {
    Name = "routetable_public-${each.key}-${var.region}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
    Tier = each.value.tier
  })
}

/**
 * Internet Gateway route
 *
 * - adds default route (0.0.0.0/0) to IGW for each public route table
 * - enables internet connectivity for public subnets
 */
resource "aws_route" "public_internet" {
  for_each = local.public_subnets

  route_table_id         = aws_route_table.public[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.igw_ids[each.value.vpc_name]
}


/** ******************************** **/
/** ROUTE TABLE - SUBNET ASSOCIATION **/
/** ******************************** **/
/**
 * Route Table Association
 *
 * - associates public route tables with their corresponding subnets
 * - ensures public subnets use the correct routing configuration
 */
resource "aws_route_table_association" "public" {
  for_each = local.public_subnets

  subnet_id      = var.subnet_ids[each.value.subnet_key]
  route_table_id = aws_route_table.public[each.key].id
}
