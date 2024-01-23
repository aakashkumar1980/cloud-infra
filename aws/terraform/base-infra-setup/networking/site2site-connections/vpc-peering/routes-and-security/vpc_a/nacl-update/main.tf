module "NACL-INGRESS-VPC_B" {
  source = "../../../../../../../_templates/networking/security/nacl/ingress"

  count = length(var.ingress-rules_map)
  # using created aws components from other modules  
  rule_number = 330 + count.index
  protocol    = element(var.ingress-rules_map, count.index).protocol
  from_port   = element(var.ingress-rules_map, count.index).from_port
  to_port     = element(var.ingress-rules_map, count.index).to_port
  cidr_block  = var.destination_cidr_block-vpc_b

  nacl_id = var.vpc_a-nacl_private_id
}
