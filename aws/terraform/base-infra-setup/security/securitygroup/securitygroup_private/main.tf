module "SG" {
  source = "../../../../_templates/security/securitygroup"

  vpc_id      = var.vpc_id
  tag_path    = var.tag_path
  entity_name = "private"
}

module "SG-INGRESS_RULES" {
  source = "../../../../_templates/security/securitygroup/ingress"
  count  = length(var.ingress-rules_map)

  from_port   = element(var.ingress-rules_map, count.index).from_port
  to_port     = element(var.ingress-rules_map, count.index).to_port
  protocol    = element(var.ingress-rules_map, count.index).protocol
  description = element(var.ingress-rules_map, count.index).description
  cidr_blocks = (
    # ping/epidermal port set to open cidr since the private nacl is network is via. nat instance 
    (element(var.ingress-rules_map, count.index).description == "epidermal port")
  ) ? [element(var.ingress-rules_map, count.index).cidr_block] : [var.vpc_cidr_block]

  securitygroup_id = module.SG.output-sg.id
}
