/**
 * Local Values for Private Route Tables
 *
 * Filters the VPC configuration to extract only private subnets
 * that belong to VPCs with NAT Gateways.
 *
 * @local private_subnets - Map of private subnet information
 *        Key: "{vpc_name}/{tier}_zone_{zone}" (e.g., "vpc_a/private_zone_b")
 *        Value: Object containing:
 *          - vpc_name    : Name of the VPC (e.g., "vpc_a")
 *          - subnet_key  : Key to look up subnet ID (same as map key)
 *          - subnet_name : Human-readable name for tagging
 *          - tier        : Always "private" for this module
 *
 * How the filter works:
 *   1. Loop through each VPC in var.vpcs
 *   2. Loop through each subnet in that VPC
 *   3. Only include subnets where:
 *      - tier == "private" AND
 *      - VPC has a NAT Gateway (exists in module.nat_gateway.nat_gateway_ids)
 *   4. Merge all results into a single flat map
 *
 * Why check for NAT Gateway?
 *   Private subnets without NAT Gateways have no internet access at all.
 *   There's no point creating a route to a non-existent NAT Gateway.
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
      if s.tier == "private" && contains(keys(module.nat_gateway.nat_gateway_ids), vpc_name)
    }
  ]...)
}
