/**
  Flattened map of all subnets across all VPCs with
  - keys as "vpc_name/subnet_id" and
  - values containing subnet details as a map.
  Example:
  {
    "london" = {
      "vpc_c/1" = {
        "vpc_name" = "vpc_c"
        "name" = "generic_az_a"
        "az" = "eu-west-2a"
        "cidr" = "192.168.0.0/28"
      }
      "vpc_acopy/1" = {
        ...
      }
      ...
    "nvirginia" = {
      "vpc_a/1" = {
        "vpc_name" = "vpc_a"
        "name" = "generic_az_a"
        "az" = "us-east-1a"
        "cidr" = "10.0.0.0/27"
      }
      "vpc_a/2" = {
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
      "${vpc_name}/${s.id}" => {
        vpc_name = vpc_name
        name     = "${s.tier}_az_${s.az}"
        cidr     = s.cidr
        az       = var.az_names[var.az_letter_to_ix[s.az]]
      }
    }
  ]...)
}