/**
 * Local Variables
 *
 * Flattens the nested subnet configuration from networking.json into
 * a single map that can be used with for_each.
 *
 * Input (nested):
 *   vpcs.vpc_a.subnets = [
 *     { tier="public", cidr="10.0.0.0/27", zone="a" },
 *     { tier="private", cidr="10.0.0.32/27", zone="b" }
 *   ]
 *
 * Output (flat):
 *   {
 *     "vpc_a/public_zone_a"  = { vpc_name="vpc_a", name="public_zone_a", ... }
 *     "vpc_a/private_zone_b" = { vpc_name="vpc_a", name="private_zone_b", ... }
 *   }
 */
locals {
  subnets_flat = merge([
    for vpc_name, v in var.vpcs : {
      for s in v.subnets :
      "${vpc_name}/${s.tier}_zone_${s.zone}" => {
        vpc_name = vpc_name
        name     = "${s.tier}_zone_${s.zone}"
        cidr     = s.cidr
        az       = var.az_names[var.az_letter_to_ix[s.zone]]
      }
    }
  ]...)
}
