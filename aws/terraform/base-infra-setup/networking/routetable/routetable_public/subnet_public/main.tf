module "SUBNETS" {
  source = "../../../../../_templates/networking/routetable/routes/subnets"
  for_each = {
    for v in var.subnets : v.tags["Name"] => v if(length(regexall("(.subnet_public-)", v.tags["Name"])) != 0)
  }

  route_table_id = join(",", [
    for v in var.rt_public : v.id
    if(v.vpc_id == each.value.vpc_id
    )
  ])
  subnet_id = each.value.id
}

