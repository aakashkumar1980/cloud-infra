/**
 * For each VPC entry, instantiate one child VPC builder module.
 * This keeps region logic clean and lets you pattern-match across regions.
 */
module "vpc" {
  source   = "../vpc"
  for_each = var.vpcs

  region             = var.region
  name               = each.key
  cidr_block         = each.value.cidr_block
  subnets            = each.value.subnets
  single_nat_gateway = var.single_nat_gateway
  tags               = var.tags
}


