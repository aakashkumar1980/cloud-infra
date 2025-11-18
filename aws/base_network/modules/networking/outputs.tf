/**
 * Outputs the IDs of the created VPCs.
 */
output "vpc_ids" {
  value = module.vpc.vpc_ids
}

/**
 * Outputs the Name tags of the created VPCs.
 */
output "vpc_names" {
  value = module.vpc.vpc_names
}
/**
 * Outputs the IDs of the created Internet Gateways.
 */
output "igw_ids" {
  value = module.vpc.igw_ids
}

/**
 * Outputs the Name tags of the created Internet Gateways.
 */
output "igw_names" {
  value = module.vpc.igw_names
}

/**
 * Outputs the IDs of the created subnets.
 */
output "subnet_ids" {
  value = module.vpc.subnet_ids
}

/**
 * Outputs the Name tags of the created subnets.
 */
output "subnet_names" {
  value = module.vpc.subnet_names
}
/**
 * Outputs the IDs of the created route tables for public subnets.
 */
output "route_table_public_ids" {
  value = module.vpc.route_table_public_ids
}

/**
 * Outputs the Name tags of the created route tables for public subnets.
 */
output "route_table_public_names" {
  value = module.vpc.route_table_public_names
}

/**
 * Outputs the route information for public route tables including destinations and targets.
 */
output "route_table_public_routes" {
  value = module.vpc.route_table_public_routes
}

/**
 * Outputs the IDs of the created NAT Gateways.
 */
output "nat_gateway_ids" {
  value = module.vpc.nat_gateway_ids
}

/**
 * Outputs the Name tags of the created NAT Gateways.
 */
output "nat_gateway_names" {
  value = module.vpc.nat_gateway_names
}

/**
 * Outputs the route information for private route tables including destinations and targets.
 */
output "route_table_private_routes" {
  value = module.vpc.route_table_private_routes
}

