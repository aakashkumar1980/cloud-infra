/**
 * Route Tables Module Outputs
 *
 * Exposes route table information for both public and private subnets.
 */

/** Public Route Table Outputs */

/**
 * @output public_route_table_ids - AWS resource IDs for public route tables
 *         Used when other resources need to reference the route table
 */
output "public_route_table_ids" {
  value       = module.route_tables_public.route_table_ids
  description = "Map of public subnet keys to route table IDs"
}

/**
 * @output public_route_table_names - Name tags of public route tables
 *         Useful for display and identification in AWS Console
 */
output "public_route_table_names" {
  value       = module.route_tables_public.route_table_names
  description = "Map of public subnet keys to route table Name tags"
}

/**
 * @output public_route_table_routes - Routing information for public tables
 *         Shows destination CIDR blocks and target gateways
 */
output "public_route_table_routes" {
  value       = module.route_tables_public.route_table_routes
  description = "Public route table routing rules (destination -> Internet Gateway)"
}

/** Private Route Table Outputs */

/**
 * @output private_route_table_ids - AWS resource IDs for private route tables
 *         Used when other resources need to reference the route table
 */
output "private_route_table_ids" {
  value       = module.route_tables_private.route_table_ids
  description = "Map of private subnet keys to route table IDs"
}

/**
 * @output private_route_table_names - Name tags of private route tables
 *         Useful for display and identification in AWS Console
 */
output "private_route_table_names" {
  value       = module.route_tables_private.route_table_names
  description = "Map of private subnet keys to route table Name tags"
}

/**
 * @output private_route_table_routes - Routing information for private tables
 *         Shows destination CIDR blocks and target NAT gateways
 */
output "private_route_table_routes" {
  value       = module.route_tables_private.route_table_routes
  description = "Private route table routing rules (destination -> NAT Gateway)"
}
