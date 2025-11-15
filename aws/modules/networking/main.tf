
module "vpc" {
  source      = "./vpc"
  vpcs        = var.vpcs
  common_tags = var.common_tags
  region      = var.region
}


module "subnets" {
  source           = "./subnets"
  vpcs             = var.vpcs
  vpc_ids          = module.vpc.vpc_ids
  az_names         = var.az_names
  az_letter_to_ix  = var.az_letter_to_ix
  common_tags      = var.common_tags
  region           = var.region
}


module "internet_gateway" {
  source      = "./internet_gateway"
  vpcs        = var.vpcs
  vpc_ids     = module.vpc.vpc_ids
  common_tags = var.common_tags
  region      = var.region
}


module "route_tables" {
  source      = "./route_tables"
  vpcs        = var.vpcs
  vpc_ids     = module.vpc.vpc_ids
  igw_ids     = module.internet_gateway.igw_ids
  subnet_ids  = module.subnets.subnet_ids
  common_tags = var.common_tags
  region      = var.region
}