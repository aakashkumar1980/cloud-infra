/**
 * VPC Module
 *
 * Creates Virtual Private Clouds (VPCs) and orchestrates the creation
 * of all related networking components.
 *
 * Resources created:
 *   - VPCs with custom CIDR blocks
 *   - Internet Gateways (via internet_gateway module)
 *   - Subnets, NAT Gateways, Route Tables (via subnets module)
 *
 * Naming Convention:
 *   {vpc_name}-{region}-{environment}-{managed_by}
 *   Example: vpc_a-nvirginia-dev-terraform
 */

/**
 * VPC Resource
 *
 * Creates one VPC for each entry in the vpcs variable.
 * Each VPC is an isolated network where you can launch AWS resources.
 *
 * @for_each var.vpcs - Creates one VPC per configuration
 * @param cidr_block  - IP address range for the VPC (e.g., "10.0.0.0/24")
 */
resource "aws_vpc" "this" {
  for_each   = var.vpcs
  cidr_block = each.value.cidr

  tags = merge(var.common_tags, {
    Name = "${each.key}-${var.region}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
  })
}

/**
 * Internet Gateway Module
 *
 * Creates one Internet Gateway per VPC.
 * Internet Gateways allow resources in public subnets to access the internet.
 */
module "internet_gateway" {
  source      = "./internet_gateway"
  vpcs        = var.vpcs
  vpc_ids     = { for k, v in aws_vpc.this : k => v.id }
  common_tags = var.common_tags
  region      = var.region
}

/**
 * Subnets Module
 *
 * Creates subnets within each VPC along with:
 *   - NAT Gateways for private subnet internet access
 *   - Route Tables for traffic routing
 */
module "subnets" {
  source          = "./subnets"
  vpcs            = var.vpcs
  vpc_ids         = { for k, v in aws_vpc.this : k => v.id }
  az_names        = var.az_names
  az_letter_to_ix = var.az_letter_to_ix
  igw_ids         = module.internet_gateway.igw_ids
  igw_names       = module.internet_gateway.igw_names
  common_tags     = var.common_tags
  region          = var.region
}
