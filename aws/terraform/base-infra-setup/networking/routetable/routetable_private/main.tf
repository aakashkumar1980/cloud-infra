module "ROUTETABLE" {
  source   = "../../../../_templates/networking/routetable"
  for_each = { for k, v in var.vpc : k => v }

  vpc_id      = each.value.id
  tag_path    = each.value.tags["Name"]
  entity_name = "private"

}

module "SUBNET_PRIVATE" {
  source = "./subnet_private"

  rt_private = values(module.ROUTETABLE)[*].output-rt
  subnets    = var.subnets

}


