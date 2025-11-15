/**
  Flattened map of all public subnets across all VPCs with
  - keys as "vpc_name/subnet_id" and
  - values containing subnet details as a map.

  Only includes subnets where tier == "public"
  Example:
  {
    "vpc_a/2" = {
      "vpc_name" = "vpc_a"
      "subnet_key" = "vpc_a/2"
      "tier" = "public"
    }
    "vpc_a/3" = {
      "vpc_name" = "vpc_a"
      "subnet_key" = "vpc_a/3"
      "tier" = "public"
    }
  }
 */
locals {
  public_subnets = merge([
    for vpc_name, v in var.vpcs : {
      for s in v.subnets :
      "${vpc_name}/${s.id}" => {
        vpc_name   = vpc_name
        subnet_key = "${vpc_name}/${s.id}"
        tier       = s.tier
      }
      if s.tier == "public"
    }
  ]...)
}
