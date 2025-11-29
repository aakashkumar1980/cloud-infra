/**
 * Outputs
 *
 * Exposes IDs and names of all networking resources created by this module.
 */

/** VPC outputs */
output "vpc_ids" {
  value       = { for k, v in aws_vpc.this : k => v.id }
  description = "Map of VPC names to VPC IDs"
}
output "vpc_names" {
  value       = { for k, v in aws_vpc.this : k => v.tags["Name"] }
  description = "Map of VPC names to VPC Name tags"
}
output "vpc_cidrs" {
  value       = { for k, v in aws_vpc.this : k => v.cidr_block }
  description = "Map of VPC names to VPC CIDR blocks"
}

/** Internet Gateway outputs */
output "igw_ids" {
  value       = module.internet_gateway.igw_ids
  description = "Map of VPC names to Internet Gateway IDs"
}
output "igw_names" {
  value       = module.internet_gateway.igw_names
  description = "Map of VPC names to Internet Gateway Name tags"
}

/** Subnet outputs */
output "subnet_ids" {
  value       = module.subnets.subnet_ids
  description = "Map of subnet keys to subnet IDs"
}
output "subnet_names" {
  value       = module.subnets.subnet_names
  description = "Map of subnet keys to subnet Name tags"
}
output "subnet_cidrs" {
  value       = module.subnets.subnet_cidrs
  description = "Map of subnet keys to subnet CIDR blocks"
}

/** Public Route Table outputs */
output "route_table_public_ids" {
  value       = module.subnets.route_table_public_ids
  description = "Map of subnet keys to public route table IDs"
}
output "route_table_public_names" {
  value       = module.subnets.route_table_public_names
  description = "Map of subnet keys to public route table Name tags"
}
output "route_table_public_routes" {
  value       = module.subnets.route_table_public_routes
  description = "Public route table routing information"
}

/** NAT Gateway outputs */
output "nat_gateway_ids" {
  value       = module.subnets.nat_gateway_ids
  description = "Map of VPC names to NAT Gateway IDs"
}
output "nat_gateway_public_ips" {
  value       = module.subnets.nat_gateway_public_ips
  description = "Map of VPC names to NAT Gateway public IPs"
}
output "nat_gateway_names" {
  value       = module.subnets.nat_gateway_names
  description = "Map of VPC names to NAT Gateway Name tags"
}

/** Private Route Table outputs */
output "route_table_private_ids" {
  value       = module.subnets.route_table_private_ids
  description = "Map of subnet keys to private route table IDs"
}
output "route_table_private_names" {
  value       = module.subnets.route_table_private_names
  description = "Map of subnet keys to private route table Name tags"
}
output "route_table_private_routes" {
  value       = module.subnets.route_table_private_routes
  description = "Private route table routing information"
}
