module "NACL-INGRESS-VPC_A" {
  source = "../../../../../../../_templates/networking/security/nacl/ingress"

  # using created aws components from other modules  
  rule_number = 225
  protocol    = -1
  from_port   = 0
  to_port     = 65535
  cidr_block  = var.destination_cidr_block-vpc_a

  nacl_id = var.vpc_b-nacl_private_id
}

module "NACL-INGRESS-VPC_C" {
  source = "../../../../../../../_templates/networking/security/nacl/ingress"

  # using created aws components from other modules  
  rule_number = 226
  protocol    = -1
  from_port   = 0
  to_port     = 65535
  cidr_block  = var.destination_cidr_block-vpc_c

  nacl_id = var.vpc_b-nacl_private_id
}
