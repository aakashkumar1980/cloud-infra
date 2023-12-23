locals {
  vpc = {
    vpc-region_nvirginia = flatten([
      for region_name, region in var.region_configurations : 
      region_name == "region_nvirginia" ? [
        for vpc_name, vpc in region.vpc : {
          region-name    = region_name
          vpc-name       = vpc_name
          vpc-cidr_block = vpc.cidr_block
        }
      ] : []
    ])
    subnets-region_nvirginia = flatten([
      for region_name, region in var.region_configurations : 
      region_name == "region_nvirginia" ? [
        for vpc_name, vpc in region.vpc : [
          for subnet_index, subnet in vpc.subnets : {
            region-name    = region_name
            vpc-name       = vpc_name
            vpc-cidr_block = vpc.cidr_block

            subnet-index                   = subnet_index
            subnet-type                    = subnet.type
            subnet-cidr_block              = subnet.cidr_block
            subnet-availability_zone_index = subnet.availability_zone_index
          }
        ]
      ] : []
    ])

    vpc-region_london = flatten([
      for region_name, region in var.region_configurations : 
      region_name == "region_london" ? [
        for vpc_name, vpc in region.vpc : {
          region-name    = region_name
          vpc-name       = vpc_name
          vpc-cidr_block = vpc.cidr_block
        }
      ] : []
    ])
    subnets-region_london = flatten([
      for region_name, region in var.region_configurations : 
      region_name == "region_london" ? [
        for vpc_name, vpc in region.vpc : [
          for subnet_index, subnet in vpc.subnets : {
            region-name    = region_name
            vpc-name       = vpc_name
            vpc-cidr_block = vpc.cidr_block

            subnet-index                   = subnet_index
            subnet-type                    = subnet.type
            subnet-cidr_block              = subnet.cidr_block
            subnet-availability_zone_index = subnet.availability_zone_index
          }
        ]
      ] : []
    ])
  }
}
