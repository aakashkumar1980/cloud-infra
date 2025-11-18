/**
 * ============================================================================
 * NAT Gateway Module - Local Variables
 * ============================================================================
 * This file contains local variables for identifying which VPCs need NAT
 * Gateways and determining the public subnets where they should be placed.
 * ============================================================================
 */

/**
 * VPCs that need NAT gateways
 *
 * Defines the set of VPCs that require NAT Gateway resources.
 * Currently: vpc_a and vpc_c
 */
locals {
  // VPCs that need NAT gateways: vpc_a and vpc_c
  nat_gateway_vpcs = toset(["vpc_a", "vpc_c"])

  /**
   * Flattened map of all public subnets across all VPCs with
   * - keys as "vpc_name/tier_zone_z" and
   * - values containing subnet details as a map.
   *
   * Only includes subnets where tier == "public"
   * This uses the same logic as route_tables/public/locals.tf
   *
   * Example:
   * {
   *   "vpc_a/public_zone_a" = {
   *     "vpc_name" = "vpc_a"
   *     "subnet_key" = "vpc_a/public_zone_a"
   *     "subnet_name" = "subnet_public_zone_a-vpc_a"
   *     "tier" = "public"
   *   }
   *   "vpc_a/public_zone_b" = {
   *     "vpc_name" = "vpc_a"
   *     "subnet_key" = "vpc_a/public_zone_b"
   *     "subnet_name" = "subnet_public_zone_b-vpc_a"
   *     "tier" = "public"
   *   }
   * }
   */
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

  /**
   * Find the first public subnet for each VPC that needs a NAT gateway
   *
   * Iterates over the NAT gateway VPCs and selects the first public subnet
   * (alphabetically by zone) for each VPC.
   *
   * Format: { "vpc_a" = "vpc_a/public_zone_a", "vpc_c" = "vpc_c/public_zone_a" }
   */
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
