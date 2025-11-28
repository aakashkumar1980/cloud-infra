# N. Virginia Region (us-east-1)
# Creates VPCs, subnets, internet gateways, NAT gateways, and route tables
module "networking_nvirginia" {
  source    = "./modules/networking"
  providers = { aws = aws.nvirginia }

  region          = "nvirginia"
  vpcs            = local.vpcs_nvirginia
  az_names        = data.aws_availability_zones.nvirginia.names
  az_letter_to_ix = local.az_letter_to_ix
  common_tags     = local.tags_common
}

# London Region (eu-west-2)
# Creates VPCs, subnets, internet gateways, NAT gateways, and route tables
module "networking_london" {
  source    = "./modules/networking"
  providers = { aws = aws.london }

  region          = "london"
  vpcs            = local.vpcs_london
  az_names        = data.aws_availability_zones.london.names
  az_letter_to_ix = local.az_letter_to_ix
  common_tags     = local.tags_common
}
