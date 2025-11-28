# Filter to get only public subnets

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
