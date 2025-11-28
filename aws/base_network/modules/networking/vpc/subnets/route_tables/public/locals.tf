/**
 * Local Values for Public Route Tables
 *
 * Filters the VPC configuration to extract only public subnets.
 * Creates a flattened map that's easy to iterate over with for_each.
 *
 * @local public_subnets - Map of public subnet information
 *        Key: "{vpc_name}/{tier}_zone_{zone}" (e.g., "vpc_a/public_zone_a")
 *        Value: Object containing:
 *          - vpc_name    : Name of the VPC (e.g., "vpc_a")
 *          - subnet_key  : Key to look up subnet ID (same as map key)
 *          - subnet_name : Human-readable name for tagging
 *          - tier        : Always "public" for this module
 *
 * How the filter works:
 *   1. Loop through each VPC in var.vpcs
 *   2. Loop through each subnet in that VPC
 *   3. Only include subnets where tier == "public"
 *   4. Merge all results into a single flat map
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
