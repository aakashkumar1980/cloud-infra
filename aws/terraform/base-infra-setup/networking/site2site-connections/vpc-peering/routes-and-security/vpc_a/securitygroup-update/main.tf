module "SECURITYGROUP-INGRESS-VPC_B" {
  source = "../../../../../../../_templates/security/securitygroup/ingress"

  count = length(var.ingress-rules_map)
  # using created aws components from other modules  
  protocol    = element(var.ingress-rules_map, count.index).protocol
  from_port   = element(var.ingress-rules_map, count.index).from_port
  to_port     = element(var.ingress-rules_map, count.index).to_port
  description = element(var.ingress-rules_map, count.index).description
  cidr_blocks = [var.destination_cidr_block-vpc_b]

  securitygroup_id = var.securitygroup_id-vpc_a
}
