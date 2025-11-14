/**
 * Outputs the IDs of the created VPCs.
 */
output "vpc_ids" {
  value = module.vpc.vpc_ids
}

/**
 * Outputs the IDs of the created subnets.
 */
output "subnet_ids" {
  value = module.subnets.subnet_ids
}

