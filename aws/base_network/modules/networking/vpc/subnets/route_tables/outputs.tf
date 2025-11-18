/**
 * Outputs the IDs of the created public route tables.
 */
output "public_route_table_ids" {
  value = module.route_tables_public.route_table_ids
}

/**
 * Outputs the Name tags of the created public route tables.
 */
output "public_route_table_names" {
  value = module.route_tables_public.route_table_names
}

/**
 * Outputs the route information for public route tables including destinations and targets.
 */
output "public_route_table_routes" {
  value = module.route_tables_public.route_table_routes
}

/**
 * Outputs the IDs of the created private route tables.
 */
output "private_route_table_ids" {
  value = module.route_tables_private.route_table_ids
}

/**
 * Outputs the Name tags of the created private route tables.
 */
output "private_route_table_names" {
  value = module.route_tables_private.route_table_names
}

/**
 * Outputs the route information for private route tables including destinations and targets.
 */
output "private_route_table_routes" {
  value = module.route_tables_private.route_table_routes
}
