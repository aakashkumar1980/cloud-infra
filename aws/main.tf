/**
* Load and shape the network config from JSON.
* We then pass that data into region-scoped modules using provider aliases.
*/
locals {
  network_raw = jsondecode(file(var.network_config_path))

  common_tags = {
    Project   = var.project
    Env       = var.env
    Owner     = var.owner
    ManagedBy = "terraform"
  }

  region_nvirginia_vpcs = try(local.network_raw.region_nvirginia.vpc, {})
  region_london_vpcs    = try(local.network_raw.region_london.vpc, {})
}

/** Build VPCs in us-east-1 (N. Virginia) */
module "region_nvirginia" {
  source = "./modules/network/region"

  providers = {
    aws = aws.nvirginia
  }

  region             = "us-east-1"
  project            = var.project
  env                = var.env
  owner              = var.owner
  vpcs               = local.region_nvirginia_vpcs
  single_nat_gateway = var.single_nat_gateway
  extra_tags         = local.common_tags
}

/** Build VPCs in eu-west-2 (London) */
module "region_london" {
  source = "./modules/network/region"

  providers = {
    aws = aws.london
  }

  region             = "eu-west-2"
  project            = var.project
  env                = var.env
  owner              = var.owner
  vpcs               = local.region_london_vpcs
  single_nat_gateway = var.single_nat_gateway
  extra_tags         = local.common_tags
}

/** Useful outputs per region (map of VPC-name → IDs) */
output "nvirginia_vpc_ids" {
  description = "Map of VPC name to VPC ID in us-east-1"
  value       = module.region_nvirginia.vpc_ids
}

output "london_vpc_ids" {
  description = "Map of VPC name to VPC ID in eu-west-2"
  value       = module.region_london.vpc_ids
}
