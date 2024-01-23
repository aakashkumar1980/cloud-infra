module "VPC_PEERING" {
  source     = "./networking/site2site-connections/vpc-peering"
  depends_on = [module.ROUTETABLE-REGION_NVIRGINIA]
  providers = {
    aws.rgn_nvg = aws.region_nvirginia
    aws.rgn_ldn = aws.region_london
  }

  ns                = module.COMMON-REGION_NVIRGINIA.project.namespace
  ingress-rules_map = local.firewall.ingress.standard_rules
}
