/**
 * Outputs the IDs of the created subnets.
 */
output "subnet_ids" {
  value = { for k, s in aws_subnet.this : k => s.id }
}

/**
 * Outputs the Name tags of the created subnets.
 */
output "subnet_names" {
  value = { for k, s in aws_subnet.this : k => s.tags["Name"] }
}

/**
 * Outputs the IDs of the created public route tables.
 */
output "route_table_public_ids" {
  value = module.route_tables_public.route_table_ids
}

/**
 * Outputs the Name tags of the created public route tables.
 */
output "route_table_public_names" {
  value = module.route_tables_public.route_table_names
}

/**
 * Outputs the route information for public route tables including destinations and targets.
 */
output "route_table_public_routes" {
  value = module.route_tables_public.route_table_routes
}


