/**
 * Outputs the IDs of the created VPCs.
 */
output "vpc_ids" {
  value = { for k, v in aws_vpc.this : k => v.id }
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
 * Outputs the IDs of the created public route tables.
 */
output "route_table_public_ids" {
  value = module.subnets.route_table_public_ids
}