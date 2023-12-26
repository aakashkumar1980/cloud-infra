module "COMMON-REGION_NVIRGINIA" {
  source = "../../terraform"
}

/** NETWORKING */
module "VPC-REGION_NVIRGINIA" {
  source = "./vpc"
  providers = {
    aws = aws.region_nvirginia
  }

  ns          = module.COMMON-REGION_NVIRGINIA.project.namespace
  vpc_flatmap = local.vpc.vpc-region_nvirginia
}

module "SUBNETS-REGION_NVIRGINIA" {
  source = "./subnets"
  depends_on = [module.VPC-REGION_NVIRGINIA]
  providers = {
    aws = aws.region_nvirginia
  }
  
  vpc             = module.VPC-REGION_NVIRGINIA.output-vpc
  subnets_flatmap = local.vpc.subnets-region_nvirginia
}