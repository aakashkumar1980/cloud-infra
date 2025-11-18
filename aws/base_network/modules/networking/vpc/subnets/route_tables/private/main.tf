/**
 * ============================================================================
 * Private Route Tables Module - Main Configuration
 * ============================================================================
 * This module manages routing configuration for private subnets, enabling
 * internet connectivity through NAT Gateways. It creates route tables,
 * adds default routes, and associates them with private subnets.
 *
 * Purpose:
 *   - Creates dedicated route tables for each private subnet
 *   - Configures default routes (0.0.0.0/0) to NAT Gateways
 *   - Associates route tables with their corresponding private subnets
 *   - Enables outbound internet access for resources in private subnets
 *
 * Architecture:
 *   Private Subnet → Route Table → Route (0.0.0.0/0) → NAT Gateway → Internet Gateway → Internet
 *
 * Resource Creation Order:
 *   1. Route Tables (aws_route_table.private)
 *   2. Routes (aws_route.private_internet)
 *   3. Associations (aws_route_table_association.private)
 *
 * Data Flow:
 *   var.vpcs → local.private_subnets (filters private tier) → resources
 * ============================================================================
 */

/**
 * AWS Route Table Resource for Private Subnets
 *
 * Creates one route table per private subnet to control network traffic
 * routing. Route tables contain rules (routes) that determine where network
 * traffic is directed.
 *
 * Purpose:
 *   - Defines routing rules for private subnet traffic
 *   - Enables customized routing per subnet
 *   - Supports multiple route entries per table
 *
 * Key Characteristics:
 *   - One route table per private subnet (fine-grained control)
 *   - Contains implicit local route for VPC CIDR (AWS-managed)
 *   - Tagged with Tier="private" for easy filtering
 *
 * Naming Convention:
 *   Format: routetable-{subnet_name}-{region}-{environment}-{managed_by}
 *   Example: routetable-subnet_private_zone_b-vpc_c-london-dev-terraform
 *
 * @for_each local.private_subnets - Filtered map containing only private tier subnets
 * @param vpc_id - Parent VPC ID for the route table
 * @param tags - Resource tags including Name, Tier, environment, etc.
 *
 * @output id - Route table ID used for route and association resources
 * @output vpc_id - Associated VPC ID for reference
 */
resource "aws_route_table" "private" {
  // Iterate over private subnets only (filtered in locals.tf)
  // Key format: "vpc_name/subnet_id" (e.g., "vpc_c/private_zone_b")
  for_each = local.private_subnets

  // Associate route table with its parent VPC
  vpc_id = var.vpc_ids[each.value.vpc_name]

  // Merge common tags with route table-specific tags
  // Tier tag enables filtering of public vs private route tables
  tags = merge(var.common_tags, {
    Name = "routetable-${each.value.subnet_name}-${var.region}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
    Tier = each.value.tier
  })
}

/**
 * AWS Route Resource for NAT Gateway
 *
 * Adds a default route (0.0.0.0/0) to each private route table, directing
 * all non-local traffic to the NAT Gateway. This enables outbound internet
 * connectivity for resources in private subnets while keeping them
 * unreachable from the internet.
 *
 * Purpose:
 *   - Enables outbound internet access from private subnets
 *   - Routes traffic through NAT Gateway for address translation
 *   - Maintains private subnet security (no inbound internet access)
 *
 * Routing Logic:
 *   - Destination 0.0.0.0/0 (all non-VPC traffic) → NAT Gateway
 *   - VPC CIDR traffic → implicit local route (AWS-managed)
 *
 * Dependencies:
 *   - Requires route table to exist (aws_route_table.private)
 *   - Requires NAT Gateway to exist (var.nat_gateway_ids)
 *
 * @for_each local.private_subnets - Private subnets requiring internet access
 * @param route_table_id - Route table to add this route to
 * @param destination_cidr_block - 0.0.0.0/0 (all IPv4 addresses)
 * @param nat_gateway_id - NAT Gateway ID for this VPC
 *
 * @output - No direct outputs (route is part of route table)
 */
resource "aws_route" "private_internet" {
  // Create one default route per private subnet's route table
  for_each = local.private_subnets

  // Reference the route table created above
  route_table_id = aws_route_table.private[each.key].id

  // Default route - matches all traffic not covered by more specific routes
  destination_cidr_block = "0.0.0.0/0"

  // Target NAT Gateway for this VPC
  // Routes traffic through NAT Gateway for outbound internet access
  nat_gateway_id = var.nat_gateway_ids[each.value.vpc_name]
}

/**
 * AWS Route Table Association Resource
 *
 * Associates each private subnet with its corresponding route table. This
 * determines which route table controls traffic routing for the subnet.
 *
 * Purpose:
 *   - Links subnets to their routing configuration
 *   - Activates route table rules for subnet traffic
 *   - Enables the route table to control subnet routing
 *
 * Relationship:
 *   Subnet → Route Table Association → Route Table → Routes
 *
 * Key Points:
 *   - Each subnet can be associated with only one route table
 *   - Multiple subnets can share a route table (not used here)
 *   - Association is required for custom route tables
 *
 * @for_each local.private_subnets - Private subnets to associate with route tables
 * @param subnet_id - Subnet to associate with route table
 * @param route_table_id - Route table to associate with subnet
 *
 * @output id - Association ID (rarely used)
 */
resource "aws_route_table_association" "private" {
  // Associate each private subnet with its dedicated route table
  for_each = local.private_subnets

  // Subnet to be associated (using composite key from locals)
  subnet_id = var.subnet_ids[each.value.subnet_key]

  // Route table created above for this private subnet
  route_table_id = aws_route_table.private[each.key].id
}
