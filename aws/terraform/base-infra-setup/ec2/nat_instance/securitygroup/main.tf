module "SG" {
  source = "../../../../_templates/security/securitygroup"

  vpc_id      = var.vpc_id
  tag_path    = var.tag_path
  entity_name = "natgateway-server"
}

module "SG-INGRESS_RULES" {
  source = "../../../../_templates/security/securitygroup/ingress"
  count  = length(local.ingress_rules)

  from_port = element(local.ingress_rules, count.index).from_port
  to_port   = element(local.ingress_rules, count.index).to_port
  protocol  = element(local.ingress_rules, count.index).protocol
  cidr_blocks = flatten([
    for v in var.subnets : v.cidr_block if(
      (v.vpc_id == var.vpc_id)
      && (length(regexall("(.subnet_private-)", v.tags["Name"])) != 0)
    )
  ])

  securitygroup_id = module.SG.output-sg.id
}
