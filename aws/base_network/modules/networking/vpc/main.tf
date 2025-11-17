/**
 * VPC creation
 *
 * - one VPC per entry in var.vpcs
 * - cidr_block is taken from networking.yaml
 * - tags include name + region
 */
resource "aws_vpc" "this" {
  // loop over each VPC defined in var.vpcs
  for_each   = var.vpcs

  // VPC CIDR block from config
  cidr_block = each.value.cidr
  tags = merge(var.common_tags, {
    Name   = "${each.key}-${var.region}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
  })
}

/**
 * Module to create Internet Gateways for VPCs
 */
module "internet_gateway" {
  source      = "./internet_gateway"
  vpcs        = var.vpcs
  vpc_ids     = { for k, v in aws_vpc.this : k => v.id }
  common_tags = var.common_tags
  region      = var.region
}

/**
 * Module to create Subnets within VPCs
 */
module "subnets" {
  source           = "./subnets"
  vpcs             = var.vpcs
  vpc_ids          = { for k, v in aws_vpc.this : k => v.id }
  az_names         = var.az_names
  az_letter_to_ix  = var.az_letter_to_ix
  common_tags      = var.common_tags
  region           = var.region
  igw_ids          = module.internet_gateway.igw_ids
}
