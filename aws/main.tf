/** Build VPCs in us-east-1 (N. Virginia) */
module "region_nvirginia" {
  source = "./modules/network/region"
  providers = {
    aws = aws.nvirginia
  }

  region             = local.region_nvirginia
  vpcs               = local.region_nvirginia_vpcs
  single_nat_gateway = var.single_nat_gateway
  extra_tags         = local.common_tags
}

