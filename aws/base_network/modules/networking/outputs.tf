# VPC outputs
output "vpc_ids" {
  value = module.vpc.vpc_ids
}
output "vpc_names" {
  value = module.vpc.vpc_names
}

# Internet Gateway outputs
output "igw_ids" {
  value = module.vpc.igw_ids
}
output "igw_names" {
  value = module.vpc.igw_names
}

# Subnet outputs
output "subnet_ids" {
  value = module.vpc.subnet_ids
}
output "subnet_names" {
  value = module.vpc.subnet_names
}

# Public route table outputs
output "route_table_public_ids" {
  value = module.vpc.route_table_public_ids
}
output "route_table_public_names" {
  value = module.vpc.route_table_public_names
}
output "route_table_public_routes" {
  value = module.vpc.route_table_public_routes
}

# NAT Gateway outputs
output "nat_gateway_ids" {
  value = module.vpc.nat_gateway_ids
}
output "nat_gateway_names" {
  value = module.vpc.nat_gateway_names
}

# Private route table outputs
output "route_table_private_routes" {
  value = module.vpc.route_table_private_routes
}
