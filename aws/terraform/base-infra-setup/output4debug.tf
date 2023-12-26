output "debug" {
  value = [
    module.VPC-REGION_NVIRGINIA.outputmap-vpc,
    module.VPC-REGION_NVIRGINIA.output-igw
  ]

}