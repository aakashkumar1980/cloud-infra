module "COMMON-REGION_NVIRGINIA" {
  source = "../../terraform"
}


module "VPC-REGION_NVIRGINIA" {
  source = "./vpc"
  providers = {
    aws = aws.region_nvirginia
  }  

  ns          = module.COMMON-REGION_NVIRGINIA.project.namespace
  vpc_flatmap = local.vpc.vpc-region_nvirginia
}
