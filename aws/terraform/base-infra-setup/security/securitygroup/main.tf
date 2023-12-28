module "SECURITYGROUP_PUBLIC" {
  source   = "./securitygroup_public"
  for_each = { for k, v in var.vpc : k => v }

  vpc_id   = each.value.id
  tag_path = each.value.tags["Name"]

  ingress-rules_map = var.ingress-rules_map
}
