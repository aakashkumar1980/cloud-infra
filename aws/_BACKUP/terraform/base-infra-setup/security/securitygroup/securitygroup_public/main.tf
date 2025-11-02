module "SG" {
  source = "../../../../_templates/security/securitygroup"

  vpc_id      = var.vpc_id
  tag_path    = var.tag_path
  entity_name = "public"
}

module "SG-INGRESS_RULES" {
  source = "../../../../_templates/security/securitygroup/ingress"
  count  = length(var.ingress-rules_map)

  from_port   = element(var.ingress-rules_map, count.index).from_port
  to_port     = element(var.ingress-rules_map, count.index).to_port
  protocol    = element(var.ingress-rules_map, count.index).protocol
  cidr_blocks = [element(var.ingress-rules_map, count.index).cidr_block]

  securitygroup_id = module.SG.output-sg.id
}
