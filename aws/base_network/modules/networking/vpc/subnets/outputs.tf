# Subnet outputs
output "subnet_ids" {
  value = { for k, s in aws_subnet.this : k => s.id }
}
output "subnet_names" {
  value = { for k, s in aws_subnet.this : k => s.tags["Name"] }
}

# Public route table outputs
output "route_table_public_ids" {
  value = module.route_tables.public_route_table_ids
}
output "route_table_public_names" {
  value = module.route_tables.public_route_table_names
}
output "route_table_public_routes" {
  value = module.route_tables.public_route_table_routes
}

# Private route table outputs
output "route_table_private_ids" {
  value = module.route_tables.private_route_table_ids
}
output "route_table_private_names" {
  value = module.route_tables.private_route_table_names
}
output "route_table_private_routes" {
  value = module.route_tables.private_route_table_routes
}

# NAT Gateway outputs
output "nat_gateway_ids" {
  value = module.nat_gateway.nat_gateway_ids
}
output "nat_gateway_public_ips" {
  value = module.nat_gateway.nat_gateway_public_ips
}
output "nat_gateway_names" {
  value = module.nat_gateway.nat_gateway_names
}
