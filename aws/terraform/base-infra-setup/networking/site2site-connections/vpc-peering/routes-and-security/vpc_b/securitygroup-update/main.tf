module "SECURITYGROUP-INGRESS-VPC_A" {
  source = "../../../../../../../_templates/security/securitygroup/ingress"

  count = length(var.ingress-rules_map)
  # using created aws components from other modules  
  protocol    = element(var.ingress-rules_map, count.index).protocol
  from_port   = element(var.ingress-rules_map, count.index).from_port
  to_port     = element(var.ingress-rules_map, count.index).to_port
  description = element(var.ingress-rules_map, count.index).description
  cidr_blocks = [var.destination_cidr_block-vpc_a]

  securitygroup_id = var.vpc_b-sg_private_id
}

module "SECURITYGROUP-INGRESS-VPC_C" {
  source = "../../../../../../../_templates/security/securitygroup/ingress"

  count = length(var.ingress-rules_map)
  # using created aws components from other modules  
  protocol    = element(var.ingress-rules_map, count.index).protocol
  from_port   = element(var.ingress-rules_map, count.index).from_port
  to_port     = element(var.ingress-rules_map, count.index).to_port
  description = element(var.ingress-rules_map, count.index).description
  cidr_blocks = [var.destination_cidr_block-vpc_c]

  securitygroup_id = var.vpc_b-sg_private_id
}
