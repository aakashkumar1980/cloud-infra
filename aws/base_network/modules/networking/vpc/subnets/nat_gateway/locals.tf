/**
 * Local Variables
 *
 * Determines which VPCs need NAT Gateways and where to place them.
 *
 * Logic:
 *   1. nat_gateway_vpcs: Derived from config - VPCs where nat_gateway = true
 *   2. public_subnets: Find all public subnets across all VPCs
 *   3. nat_gateway_subnets: Select first public subnet per VPC for NAT Gateway placement
 *
 * Note: NAT Gateways must be placed in public subnets because they need
 *       a route to the Internet Gateway.
 *
 * Configuration:
 *   Set "nat_gateway": true in networking.json for VPCs that need NAT Gateways.
 */
locals {
  nat_gateway_vpcs = toset([
    for vpc_name, vpc in var.vpcs : vpc_name
    if try(vpc.nat_gateway, false) == true
  ])

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
