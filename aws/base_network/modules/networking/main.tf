/**
 * Module to create VPCs
 */
module "vpc" {
  source      = "./vpc"
  vpcs        = var.vpcs
  common_tags = var.common_tags
  region      = var.region
}
/**
 * Module to create Internet Gateways for VPCs
 */
module "internet_gateway" {
  source      = "./internet_gateway"
  vpcs        = var.vpcs
  vpc_ids     = module.vpc.vpc_ids
  common_tags = var.common_tags
  region      = var.region
}

/**
 * Module to create Subnets within VPCs
 */
module "subnets" {
  source           = "./subnets"
  vpcs             = var.vpcs
  vpc_ids          = module.vpc.vpc_ids
  az_names         = var.az_names
  az_letter_to_ix  = var.az_letter_to_ix
  common_tags      = var.common_tags
  region           = var.region
}
/**
 * Module to create Route Tables for Public Subnets and assign Internet Gateway routes
 */
module "route_tables_public" {
  source      = "./route_tables/public_subnets"
  vpcs        = var.vpcs
  vpc_ids     = module.vpc.vpc_ids
  igw_ids     = module.internet_gateway.igw_ids
  subnet_ids  = module.subnets.subnet_ids
  common_tags = var.common_tags
  region      = var.region
}