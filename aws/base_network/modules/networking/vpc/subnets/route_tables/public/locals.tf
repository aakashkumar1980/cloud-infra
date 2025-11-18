/**
  Flattened map of all public subnets across all VPCs with
  - keys as "vpc_name/tier_az" and
  - values containing subnet details as a map.

  Only includes subnets where tier == "public"
  Example:
  {
    "vpc_a/public_a" = {
      "vpc_name" = "vpc_a"
      "subnet_key" = "vpc_a/public_a"
      "tier" = "public"
    }
    "vpc_a/public_b" = {
      "vpc_name" = "vpc_a"
      "subnet_key" = "vpc_a/public_b"
      "tier" = "public"
    }
  }
 */
locals {
  public_subnets = merge([
    for vpc_name, v in var.vpcs : {
      for s in v.subnets :
      "${vpc_name}/${s.tier}_${s.az}" => {
        vpc_name   = vpc_name
        subnet_key = "${vpc_name}/${s.tier}_${s.az}"
        tier       = s.tier
      }
      if s.tier == "public"
    }
  ]...)
}
