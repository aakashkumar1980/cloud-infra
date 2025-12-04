/**
 * VPC Modules - Multi-Region Deployment
 *
 * Creates complete network infrastructure for each configured region:
 *   - VPCs (Virtual Private Clouds)
 *   - Subnets (public and private)
 *   - Internet Gateways (for public internet access)
 *   - NAT Gateways (for private subnet outbound access)
 *   - Route Tables (traffic routing rules)
 *
 * TERRAFORM LIMITATION:
 *   Module blocks with different provider aliases cannot use for_each.
 *   The `providers` argument requires static references, so each region
 *   needs its own module block. However, all modules share the same
 *   structure and reference the dynamic `local.vpcs[region]` map.
 *
 * To add a new region:
 *   1. Add to local.regions in locals.tf
 *   2. Add provider block in providers.tf
 *   3. Add data source and module block below (copy existing pattern)
 */

# ─────────────────────────────────────────────────────────────────────────────
# N. Virginia Region (us-east-1)
# ─────────────────────────────────────────────────────────────────────────────
module "vpc_nvirginia" {
  source    = "./modules/vpc"
  providers = { aws = aws.nvirginia }

  vpcs            = local.vpcs["nvirginia"]
  az_names        = data.aws_availability_zones.nvirginia.names
  az_letter_to_ix = local.az_letter_to_ix
  common_tags     = merge(local.tags_common, { region = "nvirginia" })
}

# ─────────────────────────────────────────────────────────────────────────────
# London Region (eu-west-2)
# ─────────────────────────────────────────────────────────────────────────────
module "vpc_london" {
  source    = "./modules/vpc"
  providers = { aws = aws.london }

  vpcs            = local.vpcs["london"]
  az_names        = data.aws_availability_zones.london.names
  az_letter_to_ix = local.az_letter_to_ix
  common_tags     = merge(local.tags_common, { region = "london" })
}
