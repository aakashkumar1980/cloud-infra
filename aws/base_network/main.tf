
module "networking_nvirginia" {
  source    = "../modules/networking"
  providers = { aws = aws.nvirginia }

  region          = "us-east-1"
  vpcs            = local.vpcs_nvirginia
  az_names        = data.aws_availability_zones.nvirginia.names
  az_letter_to_ix = local.az_letter_to_ix
  common_tags     = local.tags_common
}

module "networking_london" {
  source    = "../modules/networking"
  providers = { aws = aws.london }

  region          = "eu-west-2"
  vpcs            = local.vpcs_london
  az_names        = data.aws_availability_zones.london.names
  az_letter_to_ix = local.az_letter_to_ix
  common_tags     = local.tags_common
}
