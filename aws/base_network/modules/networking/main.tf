/**
 * Module to create VPCs
 */
module "vpc" {
  source          = "./vpc"
  vpcs            = var.vpcs
  az_names        = var.az_names
  az_letter_to_ix = var.az_letter_to_ix
  common_tags     = var.common_tags
  region          = var.region
}
