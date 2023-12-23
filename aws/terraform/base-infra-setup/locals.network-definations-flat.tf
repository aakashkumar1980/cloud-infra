/**
  Reducing the network configurations (taken from variables.network-definations.tf file) in a flat structure. e.g.:
  locals (map)
  └─ vpc (map)
    ├─ vpc-region_nvirginia (list of objects)
    │  ├─ region-name (string): "region_nvirginia"
    │  ├─ vpc-name (string): "vpc_a"
    │  ├─ vpc-cidr_block (string): "10.0.0.0/24"
    |  ...
    └─ subnets-region_nvirginia (list of objects)
    |  ├─ region-name (string): "region_nvirginia"
    |  ├─ vpc-name (string): "vpc_a"
    |  ├─ vpc-cidr_block (string): "10.0.0.0/24"
    |  ├─ subnet-index (string): "1"
    |  ├─ subnet-type (string): "generic"
    |  ├─ subnet-cidr_block (string): "10.0.0.0/28"
    |  ├─ subnet-availability_zone_index (string): "a"
    |   ...
    | 
    ├─ vpc-region_london (list of objects)
        ...
**/

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
