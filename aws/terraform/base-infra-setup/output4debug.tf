output "debug" {
  value = [
    module.VPC-REGION_NVIRGINIA.output-vpc,
    module.VPC-REGION_NVIRGINIA.output-igw,
    module.SUBNETS-REGION_NVIRGINIA.output-subnets
  ]

}