/**
  Flattened map of all subnets across all VPCs with
  - keys as "vpc_name/tier_zone_z" and
  - values containing subnet details as a map.
  Example:
  {
    "london" = {
      "vpc_c/public_zone_a" = {
        "vpc_name" = "vpc_c"
        "name" = "subnet_public_zone_a-vpc_c"
        "az" = "eu-west-2a"
        "cidr" = "192.168.0.0/28"
      }
      "vpc_acopy/public_zone_a" = {
        ...
      }
      ...
    "nvirginia" = {
      "vpc_a/public_zone_a" = {
        "vpc_name" = "vpc_a"
        "name" = "subnet_public_zone_a-vpc_a"
        "az" = "us-east-1a"
        "cidr" = "10.0.0.0/27"
      }
      "vpc_a/public_zone_b" = {
        ...
      }
      ...
    }
  }
 */
locals {
  subnets_flat = merge([
    for vpc_name, v in var.vpcs : {
      for s in v.subnets :
      "${vpc_name}/${s.tier}_zone_${s.zone}" => {
        vpc_name = vpc_name
        name     = "subnet_${s.tier}_zone_${s.zone}-${vpc_name}"
        cidr     = s.cidr
        az       = var.az_names[var.az_letter_to_ix[s.zone]]
      }
    }
  ]...)
}