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
  value = module.route_tables.public_route_table_ids
}

/**
 * Outputs the Name tags of the created public route tables.
 */
output "route_table_public_names" {
  value = module.route_tables.public_route_table_names
}

/**
 * Outputs the route information for public route tables including destinations and targets.
 */
output "route_table_public_routes" {
  value = module.route_tables.public_route_table_routes
}

/**
 * Outputs the IDs of the created private route tables.
 */
output "route_table_private_ids" {
  value = module.route_tables.private_route_table_ids
}

/**
 * Outputs the Name tags of the created private route tables.
 */
output "route_table_private_names" {
  value = module.route_tables.private_route_table_names
}

/**
 * Outputs the route information for private route tables including destinations and targets.
 */
output "route_table_private_routes" {
  value = module.route_tables.private_route_table_routes
}

/**
 * Outputs the IDs of the created NAT Gateways.
 */
output "nat_gateway_ids" {
  value = module.nat_gateway.nat_gateway_ids
}

/**
 * Outputs the public IPs of the created NAT Gateways.
 */
output "nat_gateway_public_ips" {
  value = module.nat_gateway.nat_gateway_public_ips
}

/**
 * Outputs the Name tags of the created NAT Gateways.
 */
output "nat_gateway_names" {
  value = module.nat_gateway.nat_gateway_names
}

