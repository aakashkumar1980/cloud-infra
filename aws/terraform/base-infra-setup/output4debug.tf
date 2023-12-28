output "debug" {
  value = [
    /** NETWORKING **/
    module.VPC-REGION_NVIRGINIA.output-vpc,
    module.VPC-REGION_NVIRGINIA.output-igw,

    module.SUBNETS-REGION_NVIRGINIA.output-subnets,
    
    module.ROUTETABLE-REGION_NVIRGINIA.output-rt_generic,
    module.ROUTETABLE-REGION_NVIRGINIA.output-rt_public,
    module.ROUTETABLE-REGION_NVIRGINIA.output-rt_private,
    
    module.NACL-REGION_NVIRGINIA.output-nacl_generic,
    module.NACL-REGION_NVIRGINIA.output-nacl_public,
    module.NACL-REGION_NVIRGINIA.output-nacl_private,

    /** EC2 */
    module.SECURITYGROUP-REGION_NVIRGINIA.output-sg_public,
    
    
  ]

}
