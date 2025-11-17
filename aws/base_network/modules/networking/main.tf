/**
 * Module to create VPCs with nested Internet Gateways, Subnets, and Route Tables
 */
module "vpc" {
  source           = "./vpc"
  vpcs             = var.vpcs
  common_tags      = var.common_tags
  region           = var.region
  az_names         = var.az_names
  az_letter_to_ix  = var.az_letter_to_ix
}