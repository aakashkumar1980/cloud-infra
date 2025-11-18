/**
 * Outputs the IDs of the created VPCs.
 */
output "vpc_ids" {
  value = module.vpc.vpc_ids
}
/**
 * Outputs the IDs of the created Internet Gateways.
 */
output "igw_ids" {
  value = module.vpc.igw_ids
}

/**
 * Outputs the IDs of the created subnets.
 */
output "subnet_ids" {
  value = module.vpc.subnet_ids
}
/**
 * Outputs the IDs of the created route tables for public subnets.
 */
output "route_table_public_ids" {
  value = module.vpc.route_table_public_ids
}

