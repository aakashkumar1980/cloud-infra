/**
  Flattened map of all public subnets across all VPCs with
  - keys as "vpc_name/tier_zone_z" and
  - values containing subnet details as a map.

  Only includes subnets where tier == "public"
  Example:
  {
    "vpc_a/public_zone_a" = {
      "vpc_name" = "vpc_a"
      "subnet_key" = "vpc_a/public_zone_a"
      "subnet_name" = "subnet_public_zone_a-vpc_a"
      "tier" = "public"
    }
    "vpc_a/public_zone_b" = {
      "vpc_name" = "vpc_a"
      "subnet_key" = "vpc_a/public_zone_b"
      "subnet_name" = "subnet_public_zone_b-vpc_a"
      "tier" = "public"
    }
  }
 */
locals {
  public_subnets = merge([
    for vpc_name, v in var.vpcs : {
      for s in v.subnets :
      "${vpc_name}/${s.tier}_zone_${s.zone}" => {
        vpc_name    = vpc_name
        subnet_key  = "${vpc_name}/${s.tier}_zone_${s.zone}"
        subnet_name = "subnet_${s.tier}_zone_${s.zone}-${vpc_name}"
        tier        = s.tier
      }
      if s.tier == "public"
    }
  ]...)
}
