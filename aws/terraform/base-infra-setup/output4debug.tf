output "debug" {
  value = [
    module.VPC-REGION_NVIRGINIA.output-vpc,
    module.VPC-REGION_NVIRGINIA.output-igw,

    module.SUBNETS-REGION_NVIRGINIA.output-subnets,
    /**
    module.ROUTETABLE-REGION_NVIRGINIA.output-rt_generic,
    module.ROUTETABLE-REGION_NVIRGINIA.output-rt_public,
    module.ROUTETABLE-REGION_NVIRGINIA.output-rt_private,
    **/
  ]

}
