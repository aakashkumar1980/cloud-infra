locals {
  subnets_flat = merge([
    for vpc_name, v in var.vpcs : {
      for s in v.subnets :
      "${vpc_name}/${s.id}" => {
        vpc_name = vpc_name
        name     = s.name
        tier     = s.tier
        cidr     = s.cidr
        az       = var.az_names[var.az_letter_to_ix[s.az]]
      }
    }
  ]...)
}