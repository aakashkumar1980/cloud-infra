/**
 * Outputs
 *
 * Exposes subnet, route table, and NAT Gateway information.
 */

/** Subnet outputs */
output "subnet_ids" {
  value       = { for k, s in aws_subnet.this : k => s.id }
  description = "Map of subnet keys to subnet IDs"
}
output "subnet_names" {
  value       = { for k, s in aws_subnet.this : k => s.tags["Name"] }
  description = "Map of subnet keys to subnet Name tags"
}

/** Public Route Table outputs */
output "route_table_public_ids" {
  value       = module.route_tables.public_route_table_ids
  description = "Map of subnet keys to public route table IDs"
}
output "route_table_public_names" {
  value       = module.route_tables.public_route_table_names
  description = "Map of subnet keys to public route table Name tags"
}
output "route_table_public_routes" {
  value       = module.route_tables.public_route_table_routes
  description = "Public route table routing information"
}

/** Private Route Table outputs */
output "route_table_private_ids" {
  value       = module.route_tables.private_route_table_ids
  description = "Map of subnet keys to private route table IDs"
}
output "route_table_private_names" {
  value       = module.route_tables.private_route_table_names
  description = "Map of subnet keys to private route table Name tags"
}
output "route_table_private_routes" {
  value       = module.route_tables.private_route_table_routes
  description = "Private route table routing information"
}

/** NAT Gateway outputs */
output "nat_gateway_ids" {
  value       = module.nat_gateway.nat_gateway_ids
  description = "Map of VPC names to NAT Gateway IDs"
}
output "nat_gateway_public_ips" {
  value       = module.nat_gateway.nat_gateway_public_ips
  description = "Map of VPC names to NAT Gateway public IPs"
}
output "nat_gateway_names" {
  value       = module.nat_gateway.nat_gateway_names
  description = "Map of VPC names to NAT Gateway Name tags"
}
