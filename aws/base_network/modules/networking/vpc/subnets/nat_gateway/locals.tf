# Determine which VPCs need NAT Gateways and where to place them

locals {
  # VPCs that need NAT gateways (must have public subnets)
  nat_gateway_vpcs = toset(["vpc_a", "vpc_c"])

  # Get all public subnets
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

  # Select first public subnet per VPC for NAT Gateway placement
  nat_gateway_subnets = {
    for vpc_name in local.nat_gateway_vpcs :
    vpc_name => [
      for subnet_key, subnet in local.public_subnets :
      subnet_key
      if subnet.vpc_name == vpc_name
    ][0]
    if length([
      for subnet_key, subnet in local.public_subnets :
      subnet_key
      if subnet.vpc_name == vpc_name
    ]) > 0
  }
}
