module "INTERNET-GATEWAY" {
  source = "../../../../../_templates/networking/routetable/routes/igw"
  count  = length(var.rt_public)

  rt_id                  = element(var.rt_public, count.index).id
  destination_cidr_block = "0.0.0.0/0"
  igw_id = join("", [
    for v in var.igw : v.id if(v.vpc_id == element(var.rt_public, count.index).vpc_id)
  ])

}
