/**
 * Networking Module for N. Virginia Region (us-east-1)
 *
 * This module creates the complete networking infrastructure for the N. Virginia region,
 * including VPCs, subnets, internet gateways, and route tables.
 *
 * @source ./modules/networking - The networking module source path
 * @provider aws.nvirginia - AWS provider configured for us-east-1 region
 *
 * @param region - Region identifier used in resource naming (nvirginia)
 * @param vpcs - Map of VPC configurations specific to N. Virginia region
 * @param az_names - List of availability zone names retrieved from AWS
 * @param az_letter_to_ix - Mapping of AZ letters (a,b,c) to indices (0,1,2)
 * @param common_tags - Common tags to apply to all resources
 *
 * @outputs vpc_ids, subnet_ids, igw_ids, route_table_public_ids
 */
module "networking_nvirginia" {
  source    = "./modules/networking"
  providers = { aws = aws.nvirginia }

  region          = "nvirginia"
  vpcs            = local.vpcs_nvirginia
  az_names        = data.aws_availability_zones.nvirginia.names
  az_letter_to_ix = local.az_letter_to_ix
  common_tags     = local.tags_common
}

/**
 * Networking Module for London Region (eu-west-2)
 *
 * This module creates the complete networking infrastructure for the London region,
 * including VPCs, subnets, internet gateways, and route tables.
 *
 * @source ./modules/networking - The networking module source path
 * @provider aws.london - AWS provider configured for eu-west-2 region
 *
 * @param region - Region identifier used in resource naming (london)
 * @param vpcs - Map of VPC configurations specific to London region
 * @param az_names - List of availability zone names retrieved from AWS
 * @param az_letter_to_ix - Mapping of AZ letters (a,b,c) to indices (0,1,2)
 * @param common_tags - Common tags to apply to all resources
 *
 * @outputs vpc_ids, subnet_ids, igw_ids, route_table_public_ids
 */
module "networking_london" {
  source    = "./modules/networking"
  providers = { aws = aws.london }

  region          = "london"
  vpcs            = local.vpcs_london
  az_names        = data.aws_availability_zones.london.names
  az_letter_to_ix = local.az_letter_to_ix
  common_tags     = local.tags_common
}
