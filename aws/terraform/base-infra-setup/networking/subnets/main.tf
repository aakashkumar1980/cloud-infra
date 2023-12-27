module "SUBNETS" {
  source = "../../../_templates/networking/subnets"
  for_each = {
    // update the key for grouping
    for k in var.subnets_flatmap : "${k.region-name}.${k.vpc-name}.${k.subnet-index}" => k
  }

  # using created aws components from other modules
  vpc_id                  = join("", lookup(var.vpc, "${each.value.region-name}.${each.value.vpc-name}")[*].id)
  availability_zone       = each.value.subnet-availability_zone_index
  cidr_block              = each.value.subnet-cidr_block
  map_public_ip_on_launch = each.value.subnet-type == "private" ? false : true

  tag_path                       = join("", lookup(var.vpc, "${each.value.region-name}.${each.value.vpc-name}")[*].tags["Name"])
  subnet-type                    = each.value.subnet-type
  subnet-availability_zone_index = each.value.subnet-availability_zone_index

}
