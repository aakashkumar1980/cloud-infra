module "NACL-INGRESS-VPC_A" {
  source = "../../../../../../../_templates/networking/security/nacl/ingress"

  # using created aws components from other modules  
  rule_number = 250
  protocol    = -1
  from_port   = 0
  to_port     = 65535
  cidr_block  = var.destination_cidr_block-vpc_a

  nacl_id = var.vpc_c-nacl_private_id
}

module "NACL-INGRESS-VPC_B" {
  source = "../../../../../../../_templates/networking/security/nacl/ingress"

  # using created aws components from other modules  
  rule_number = 251
  protocol    = -1
  from_port   = 0
  to_port     = 65535
  cidr_block  = var.destination_cidr_block-vpc_b

  nacl_id = var.vpc_c-nacl_private_id
}
