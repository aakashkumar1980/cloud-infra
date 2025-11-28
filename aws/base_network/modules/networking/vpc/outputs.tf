# VPC outputs
output "vpc_ids" {
  value = { for k, v in aws_vpc.this : k => v.id }
}
output "vpc_names" {
  value = { for k, v in aws_vpc.this : k => v.tags["Name"] }
}

# Internet Gateway outputs
output "igw_ids" {
  value = module.internet_gateway.igw_ids
}
output "igw_names" {
  value = module.internet_gateway.igw_names
}

# Subnet outputs
output "subnet_ids" {
  value = module.subnets.subnet_ids
}
output "subnet_names" {
  value = module.subnets.subnet_names
}

# Public route table outputs
output "route_table_public_ids" {
  value = module.subnets.route_table_public_ids
}
output "route_table_public_names" {
  value = module.subnets.route_table_public_names
}
output "route_table_public_routes" {
  value = module.subnets.route_table_public_routes
}

# NAT Gateway outputs
output "nat_gateway_ids" {
  value = module.subnets.nat_gateway_ids
}
output "nat_gateway_public_ips" {
  value = module.subnets.nat_gateway_public_ips
}
output "nat_gateway_names" {
  value = module.subnets.nat_gateway_names
}

# Private route table outputs
output "route_table_private_ids" {
  value = module.subnets.route_table_private_ids
}
output "route_table_private_names" {
  value = module.subnets.route_table_private_names
}
output "route_table_private_routes" {
  value = module.subnets.route_table_private_routes
}
