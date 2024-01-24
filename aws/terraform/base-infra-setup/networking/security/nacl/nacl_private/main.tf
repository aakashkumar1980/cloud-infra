module "NACL" {
  source = "../../../../../_templates/networking/security/nacl"

  vpc_id = var.vpc_id
  subnet_ids = flatten([
    for v in var.subnets : v.id if(
      length(regexall("(.subnet_private-)", v.tags["Name"])) != 0
      && v.vpc_id == var.vpc_id
    )
  ])

  tag_path    = var.tag_path
  entity_name = "nacl_private"
}

module "NACL-INGRESS_RULES" {
  source = "../../../../../_templates/networking/security/nacl/ingress"
  count  = length(var.ingress-rules_map)

  # using created aws components from other modules  
  rule_number = 100 + count.index
  protocol    = element(var.ingress-rules_map, count.index).protocol
  from_port   = element(var.ingress-rules_map, count.index).from_port
  to_port     = element(var.ingress-rules_map, count.index).to_port
  cidr_block = (
    # ping/epidermal port set to open cidr since the private nacl is network is via. nat instance 
    (element(var.ingress-rules_map, count.index).description == "epidermal port")
  ) ? "0.0.0.0/0" : var.vpc_cidr_block

  nacl_id = module.NACL.output-nacl.id
}
module "NACL-EGRESS_RULES" {
  source = "../../../../../_templates/networking/security/nacl/egress"
  count  = length(var.egress-rules_map)

  # using created aws components from other modules  
  rule_number = 125 + count.index
  protocol    = element(var.egress-rules_map, count.index).protocol
  from_port   = element(var.egress-rules_map, count.index).from_port
  to_port     = element(var.egress-rules_map, count.index).to_port
  cidr_block  = element(var.egress-rules_map, count.index).cidr_block

  nacl_id = module.NACL.output-nacl.id
}
