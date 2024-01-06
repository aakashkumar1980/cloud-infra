module "ROUTETABLE" {
  source   = "../../../../_templates/networking/routetable"
  for_each = { for k, v in var.vpc : k => v }

  vpc_id      = each.value.id
  tag_path    = each.value.tags["Name"]
  entity_name = "generic"
}

module "INTERNET-GATEWAY" {
  source = "./igw"

  rt_generic = values(module.ROUTETABLE)[*].output-rt
  igw        = var.igw
}
module "SUBNET_GENERIC" {
  source = "./subnet_generic"

  rt_generic = values(module.ROUTETABLE)[*].output-rt
  subnets    = var.subnets
}


