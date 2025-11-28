# Public route table outputs
output "public_route_table_ids" {
  value = module.route_tables_public.route_table_ids
}
output "public_route_table_names" {
  value = module.route_tables_public.route_table_names
}
output "public_route_table_routes" {
  value = module.route_tables_public.route_table_routes
}

# Private route table outputs
output "private_route_table_ids" {
  value = module.route_tables_private.route_table_ids
}
output "private_route_table_names" {
  value = module.route_tables_private.route_table_names
}
output "private_route_table_routes" {
  value = module.route_tables_private.route_table_routes
}
