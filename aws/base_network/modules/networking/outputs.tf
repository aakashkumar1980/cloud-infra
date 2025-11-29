/**
 * Outputs
 *
 * Exposes all networking resource IDs and names from the VPC module.
 * These outputs are used by the root module to display results.
 */

/** VPC IDs and names */
output "vpc_ids" {
  value       = module.vpc.vpc_ids
  description = "Map of VPC names to VPC IDs"
}
output "vpc_names" {
  value       = module.vpc.vpc_names
  description = "Map of VPC names to VPC Name tags"
}
output "vpc_cidrs" {
  value       = module.vpc.vpc_cidrs
  description = "Map of VPC names to VPC CIDR blocks"
}

/** Internet Gateway IDs and names */
output "igw_ids" {
  value       = module.vpc.igw_ids
  description = "Map of VPC names to Internet Gateway IDs"
}
output "igw_names" {
  value       = module.vpc.igw_names
  description = "Map of VPC names to Internet Gateway Name tags"
}

/** Subnet IDs and names */
output "subnet_ids" {
  value       = module.vpc.subnet_ids
  description = "Map of subnet keys to subnet IDs"
}
output "subnet_names" {
  value       = module.vpc.subnet_names
  description = "Map of subnet keys to subnet Name tags"
}
output "subnet_cidrs" {
  value       = module.vpc.subnet_cidrs
  description = "Map of subnet keys to subnet CIDR blocks"
}

/** Public Route Table outputs */
output "route_table_public_ids" {
  value       = module.vpc.route_table_public_ids
  description = "Map of subnet keys to public route table IDs"
}
output "route_table_public_names" {
  value       = module.vpc.route_table_public_names
  description = "Map of subnet keys to public route table Name tags"
}
output "route_table_public_routes" {
  value       = module.vpc.route_table_public_routes
  description = "Public route table routing information"
}

/** NAT Gateway IDs and names */
output "nat_gateway_ids" {
  value       = module.vpc.nat_gateway_ids
  description = "Map of VPC names to NAT Gateway IDs"
}
output "nat_gateway_names" {
  value       = module.vpc.nat_gateway_names
  description = "Map of VPC names to NAT Gateway Name tags"
}

/** Private Route Table outputs */
output "route_table_private_routes" {
  value       = module.vpc.route_table_private_routes
  description = "Private route table routing information"
}
