/**
 * For each VPC entry, instantiate one child VPC builder module.
 * This keeps region logic clean and lets you pattern-match across regions.
 */
module "vpc" {
  source   = "../vpc"
  for_each = var.vpcs

  project            = var.project
  env                = var.env
  owner              = var.owner
  region             = var.region
  name               = each.key
  cidr_block         = each.value.cidr_block
  subnets            = each.value.subnets
  single_nat_gateway = var.single_nat_gateway
  extra_tags         = var.extra_tags
}

/** Expose a tidy map: vpc_name -> vpc_id */
output "vpc_ids" {
  description = "Map of VPC name -> VPC ID"
  value       = { for k, m in module.vpc : k => m.vpc_id }
}
