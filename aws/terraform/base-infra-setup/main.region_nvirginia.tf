module "COMMON-REGION_NVIRGINIA" {
  source = "../../terraform"
}

/** NETWORKING */
module "VPC-REGION_NVIRGINIA" {
  source = "./networking/vpc"
  providers = {
    aws = aws.region_nvirginia
  }

  ns          = module.COMMON-REGION_NVIRGINIA.project.namespace
  vpc_flatmap = local.vpc.vpc-region_nvirginia
}

module "SUBNETS-REGION_NVIRGINIA" {
  source     = "./networking/subnets"
  depends_on = [module.VPC-REGION_NVIRGINIA]
  providers = {
    aws = aws.region_nvirginia
  }

  vpc             = module.VPC-REGION_NVIRGINIA.output-vpc
  subnets_flatmap = local.vpc.subnets-region_nvirginia
}

module "ROUTETABLE-REGION_NVIRGINIA" {
  source     = "./networking/routetable"
  depends_on = [module.SUBNETS-REGION_NVIRGINIA]
  providers = {
    aws = aws.region_nvirginia
  }

  vpc     = module.VPC-REGION_NVIRGINIA.output-vpc
  igw     = module.VPC-REGION_NVIRGINIA.output-igw
  subnets = module.SUBNETS-REGION_NVIRGINIA.output-subnets
}