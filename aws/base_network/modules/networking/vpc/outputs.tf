/**
 * Outputs the IDs of the created VPCs.
 */
output "vpc_ids" {
  value = { for k, v in aws_vpc.this : k => v.id }
}

/**
 * Outputs the Name tags of the created VPCs.
 */
output "vpc_names" {
  value = { for k, v in aws_vpc.this : k => v.tags["Name"] }
}

/**
 * Outputs the IDs of the created Internet Gateways.
 */
output "igw_ids" {
  value = module.internet_gateway.igw_ids
}

/**
 * Outputs the Name tags of the created Internet Gateways.
 */
output "igw_names" {
  value = module.internet_gateway.igw_names
}

/**
 * Outputs the IDs of the created subnets.
 */
output "subnet_ids" {
  value = module.subnets.subnet_ids
}

/**
 * Outputs the Name tags of the created subnets.
 */
output "subnet_names" {
  value = module.subnets.subnet_names
}

/**
 * Outputs the IDs of the created public route tables.
 */
output "route_table_public_ids" {
  value = module.subnets.route_table_public_ids
}

/**
 * Outputs the Name tags of the created public route tables.
 */
output "route_table_public_names" {
  value = module.subnets.route_table_public_names
}

/**
 * Outputs the route information for public route tables including destinations and targets.
 */
output "route_table_public_routes" {
  value = module.subnets.route_table_public_routes
}