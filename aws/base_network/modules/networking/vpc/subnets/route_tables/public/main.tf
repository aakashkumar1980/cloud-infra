/**
 * ============================================================================
 * Public Route Tables Module - Main Configuration
 * ============================================================================
 * This module manages routing configuration for public subnets, enabling
 * internet connectivity through Internet Gateways. It creates route tables,
 * adds default routes, and associates them with public subnets.
 *
 * Purpose:
 *   - Creates dedicated route tables for each public subnet
 *   - Configures default routes (0.0.0.0/0) to Internet Gateways
 *   - Associates route tables with their corresponding public subnets
 *   - Enables internet access for resources in public subnets
 *
 * Architecture:
 *   Public Subnet → Route Table → Route (0.0.0.0/0) → Internet Gateway → Internet
 *
 * Resource Creation Order:
 *   1. Route Tables (aws_route_table.public)
 *   2. Routes (aws_route.public_internet)
 *   3. Associations (aws_route_table_association.public)
 *
 * Data Flow:
 *   var.vpcs → local.public_subnets (filters public tier) → resources
 * ============================================================================
 */

/**
 * AWS Route Table Resource for Public Subnets
 *
 * Creates one route table per public subnet to control network traffic
 * routing. Route tables contain rules (routes) that determine where network
 * traffic is directed.
 *
 * Purpose:
 *   - Defines routing rules for public subnet traffic
 *   - Enables customized routing per subnet
 *   - Supports multiple route entries per table
 *
 * Key Characteristics:
 *   - One route table per public subnet (fine-grained control)
 *   - Contains implicit local route for VPC CIDR (AWS-managed)
 *   - Tagged with Tier="public" for easy filtering
 *
 * Naming Convention:
 *   Format: routetable-{subnet_name}-{region}-{environment}-{managed_by}
 *   Example: routetable-subnet_public_zone_a-vpc_a-nvirginia-dev-terraform
 *
 * @for_each local.public_subnets - Filtered map containing only public tier subnets
 * @param vpc_id - Parent VPC ID for the route table
 * @param tags - Resource tags including Name, Tier, environment, etc.
 *
 * @output id - Route table ID used for route and association resources
 * @output vpc_id - Associated VPC ID for reference
 */
resource "aws_route_table" "public" {
  // Iterate over public subnets only (filtered in locals.tf)
  // Key format: "vpc_name/subnet_id" (e.g., "vpc_a/1")
  for_each = local.public_subnets

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
 * AWS Route Resource for Internet Gateway
 *
 * Adds a default route (0.0.0.0/0) to each public route table, directing
 * all non-local traffic to the Internet Gateway. This enables internet
 * connectivity for resources in public subnets.
 *
 * Purpose:
 *   - Enables outbound internet access from public subnets
 *   - Allows inbound internet traffic to resources with public IPs
 *   - Provides the "public" in public subnets
 *
 * Routing Logic:
 *   - Destination 0.0.0.0/0 (all non-VPC traffic) → Internet Gateway
 *   - VPC CIDR traffic → implicit local route (AWS-managed)
 *
 * Dependencies:
 *   - Requires route table to exist (aws_route_table.public)
 *   - Requires Internet Gateway to exist (var.igw_ids)
 *
 * @for_each local.public_subnets - Public subnets requiring internet access
 * @param route_table_id - Route table to add this route to
 * @param destination_cidr_block - 0.0.0.0/0 (all IPv4 addresses)
 * @param gateway_id - Internet Gateway ID for this VPC
 *
 * @output - No direct outputs (route is part of route table)
 */
resource "aws_route" "public_internet" {
  // Create one default route per public subnet's route table
  for_each = local.public_subnets

  // Reference the route table created above
  route_table_id         = aws_route_table.public[each.key].id

  // Default route - matches all traffic not covered by more specific routes
  destination_cidr_block = "0.0.0.0/0"

  // Target Internet Gateway for this VPC
  gateway_id             = var.igw_ids[each.value.vpc_name]
}

/**
 * AWS Route Table Association Resource
 *
 * Associates each public subnet with its corresponding route table. This
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
 * @for_each local.public_subnets - Public subnets to associate with route tables
 * @param subnet_id - Subnet to associate with route table
 * @param route_table_id - Route table to associate with subnet
 *
 * @output id - Association ID (rarely used)
 */
resource "aws_route_table_association" "public" {
  // Associate each public subnet with its dedicated route table
  for_each = local.public_subnets

  // Subnet to be associated (using composite key from locals)
  subnet_id      = var.subnet_ids[each.value.subnet_key]

  // Route table created above for this public subnet
  route_table_id = aws_route_table.public[each.key].id
}
