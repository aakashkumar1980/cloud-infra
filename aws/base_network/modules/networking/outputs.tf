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
  value = module.internet_gateway.igw_ids
}

/**
 * Outputs the IDs of the created subnets.
 */
output "subnet_ids" {
  value = module.subnets.subnet_ids
}
/**
 * Outputs the IDs of the created route tables for public subnets.
 */
output "route_table_public_ids" {
  value = module.route_tables_public.route_table_ids
}

