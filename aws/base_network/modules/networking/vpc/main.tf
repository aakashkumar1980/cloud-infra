# VPC Module
# Creates VPCs with internet gateways, subnets, NAT gateways, and route tables
#
# Naming: {vpc_name}-{region}-{environment}-{managed_by}
# Example: vpc_a-nvirginia-dev-terraform

# Create VPCs
resource "aws_vpc" "this" {
  for_each   = var.vpcs
  cidr_block = each.value.cidr

  tags = merge(var.common_tags, {
    Name = "${each.key}-${var.region}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
  })
}

# Create Internet Gateways (one per VPC for public internet access)
module "internet_gateway" {
  source      = "./internet_gateway"
  vpcs        = var.vpcs
  vpc_ids     = { for k, v in aws_vpc.this : k => v.id }
  common_tags = var.common_tags
  region      = var.region
}

# Create Subnets, NAT Gateways, and Route Tables
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
