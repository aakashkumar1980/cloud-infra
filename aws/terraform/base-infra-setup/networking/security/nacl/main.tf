module "NACL_PUBLIC" {
  source   = "./nacl_public"
  for_each = { for k, v in var.vpc : k => v }

  vpc_id   = each.value.id
  subnets  = var.subnets
  tag_path = each.value.tags["Name"]

  ingress-rules_map = var.ingress-rules_map
  egress-rules_map  = var.egress-rules_map
}

module "NACL_PRIVATE" {
  source   = "./nacl_private"
  for_each = { for k, v in var.vpc : k => v }

  vpc_id         = each.value.id
  subnets        = var.subnets
  tag_path       = each.value.tags["Name"]
  vpc_cidr_block = each.value.cidr_block

  ingress-rules_map = var.ingress-rules_map
  egress-rules_map  = var.egress-rules_map
}

