# Flatten nested subnet configs into a single map
# Key format: "vpc_name/tier_zone_letter" (e.g., "vpc_a/public_zone_a")

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
