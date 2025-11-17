/**
 * Outputs the IDs of the created subnets.
 */
output "subnet_ids" {
  value = { for k, s in aws_subnet.this : k => s.id }
}

/**
 * Outputs the IDs of the created route tables for public subnets.
 */
output "route_table_public_ids" {
  value = module.route_tables_public.route_table_ids
}


