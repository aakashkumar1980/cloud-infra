/**
  Flattened map of all private subnets across all VPCs with
  - keys as "vpc_name/tier_zone_z" and
  - values containing subnet details as a map.

  Only includes subnets where tier == "private"
  Example:
  {
    "vpc_c/private_zone_b" = {
      "vpc_name" = "vpc_c"
      "subnet_key" = "vpc_c/private_zone_b"
      "subnet_name" = "subnet_private_zone_b-vpc_c"
      "tier" = "private"
    }
  }
 */
locals {
  private_subnets = merge([
    for vpc_name, v in var.vpcs : {
      for s in v.subnets :
      "${vpc_name}/${s.tier}_zone_${s.zone}" => {
        vpc_name    = vpc_name
        subnet_key  = "${vpc_name}/${s.tier}_zone_${s.zone}"
        subnet_name = "subnet_${s.tier}_zone_${s.zone}-${vpc_name}"
        tier        = s.tier
      }
      if s.tier == "private"
    }
  ]...)
}
