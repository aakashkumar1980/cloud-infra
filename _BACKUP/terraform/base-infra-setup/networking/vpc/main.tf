module "VPC" {
  source = "../../../_templates/networking/vpc"
  for_each = {
    for k in var.vpc_flatmap : "${k.region-name}.${k.vpc-name}" => k
  }

  ns         = var.ns
  vpc_name   = each.value.vpc-name
  cidr_block = each.value.vpc-cidr_block
}

module "INTERNET_GATEWAY" {
  source = "../../../_templates/networking/vpc/igw"
  for_each = {
    for k, v in values(module.VPC)[*].output-vpc : k => v
  }

  vpc_id                 = each.value.id
  default_route_table_id = each.value.default_route_table_id
  tag_path               = each.value.tags["Name"]
}


