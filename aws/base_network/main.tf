/**
 * VPC Module - N. Virginia Region (us-east-1)
 *
 * Creates the complete network infrastructure for the N. Virginia region:
 *   - VPCs (Virtual Private Clouds)
 *   - Subnets (public and private)
 *   - Internet Gateways (for public internet access)
 *   - NAT Gateways (for private subnet outbound access)
 *   - Route Tables (traffic routing rules)
 *
 * @param vpcs            - VPC configurations from networking.json
 * @param az_names        - Available availability zones in this region
 * @param az_letter_to_ix - Maps zone letters to indices
 * @param common_tags     - Tags applied to all resources
 */
module "vpc_nvirginia" {
  source    = "./modules/vpc"
  providers = { aws = aws.nvirginia }

  vpcs            = local.vpcs_nvirginia
  az_names        = data.aws_availability_zones.nvirginia.names
  az_letter_to_ix = local.az_letter_to_ix
  common_tags     = merge(local.tags_common, { "region" = local.REGION_N_VIRGINIA })
}

/**
 * VPC Module - London Region (eu-west-2)
 *
 * Creates the complete network infrastructure for the London region:
 *   - VPCs (Virtual Private Clouds)
 *   - Subnets (public and private)
 *   - Internet Gateways (for public internet access)
 *   - NAT Gateways (for private subnet outbound access)
 *   - Route Tables (traffic routing rules)
 *
 * @param vpcs            - VPC configurations from networking.json
 * @param az_names        - Available availability zones in this region
 * @param az_letter_to_ix - Maps zone letters to indices
 * @param common_tags     - Tags applied to all resources
 */
module "vpc_london" {
  source    = "./modules/vpc"
  providers = { aws = aws.london }

  vpcs            = local.vpcs_london
  az_names        = data.aws_availability_zones.london.names
  az_letter_to_ix = local.az_letter_to_ix
  common_tags     = merge(local.tags_common, { "region" = local.REGION_LONDON })
}
