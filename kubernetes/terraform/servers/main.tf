module "COMMON-BASE_INFRA_SETUP" {
  source = "../../../aws/terraform"
}
module "COMMON" {
  source = "../../terraform"
}


/** CONTROL_PLANES **/
module "CONTROL_PLANES" {
  source = "./control_planes"
  providers = {
    aws.rgn_nvg = aws.region_nvirginia
    aws.rgn_ldn = aws.region_london
  }

  base_ns = module.COMMON-BASE_INFRA_SETUP.project.namespace
}
