module "SECURITYGROUP_PUBLIC" {
  source   = "./securitygroup_public"
  for_each = { for k, v in var.vpc : k => v }

  vpc_id   = each.value.id
  tag_path = each.value.tags["Name"]

  ingress-rules_map = var.ingress-rules_map
}

module "SECURITYGROUP_PRIVATE" {
  source   = "./securitygroup_private"
  for_each = { for k, v in var.vpc : k => v }

  vpc_id         = each.value.id
  vpc_cidr_block = each.value.cidr_block
  tag_path       = each.value.tags["Name"]

  ingress-rules_map = var.ingress-rules_map
}
