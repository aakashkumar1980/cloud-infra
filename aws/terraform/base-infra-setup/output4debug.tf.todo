output "debug" {
  value = [
    /** **************** */
    /** REGION_NVIRGINIA */
    /** **************** */
    /** NETWORKING **/
    module.VPC-REGION_NVIRGINIA.output-vpc,
    module.VPC-REGION_NVIRGINIA.output-igw,

    module.SUBNETS-REGION_NVIRGINIA.output-subnets,

    module.ROUTETABLE-REGION_NVIRGINIA.output-rt_public,
    module.ROUTETABLE-REGION_NVIRGINIA.output-rt_private,

    module.NACL-REGION_NVIRGINIA.output-nacl_public,
    module.NACL-REGION_NVIRGINIA.output-nacl_private,

    /** EC2 */
    module.SECURITYGROUP-REGION_NVIRGINIA.output-sg_public,
    module.KEYPAIR-REGION_NVIRGINIA.output-keypair,

    module.EC2-REGION_NVIRGINIA.output-sg_nat,
    module.EC2-REGION_NVIRGINIA.output-ec2_nat,


    /** ************* */
    /** REGION_LONDON */
    /** ************* */
    /** NETWORKING **/
    module.VPC-REGION_LONDON.output-vpc,
    module.VPC-REGION_LONDON.output-igw,

    module.SUBNETS-REGION_LONDON.output-subnets,

    module.ROUTETABLE-REGION_LONDON.output-rt_public,
    module.ROUTETABLE-REGION_LONDON.output-rt_private,

    module.NACL-REGION_LONDON.output-nacl_public,
    module.NACL-REGION_LONDON.output-nacl_private,

    /** EC2 */
    module.SECURITYGROUP-REGION_LONDON.output-sg_public,
    module.KEYPAIR-REGION_LONDON.output-keypair,

    module.EC2-REGION_LONDON.output-sg_nat,
    module.EC2-REGION_LONDON.output-ec2_nat,

  ]

}
