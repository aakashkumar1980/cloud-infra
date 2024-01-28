module "NACL-INGRESS-VPC_B" {
  source = "../../../../../../../_templates/networking/security/nacl/ingress"

  # using created aws components from other modules  
  rule_number = 200
  protocol    = -1
  from_port   = 0
  to_port     = 65535
  cidr_block  = var.destination_cidr_block-vpc_b

  nacl_id = var.vpc_a-nacl_private_id
}

module "NACL-INGRESS-VPC_C" {
  source = "../../../../../../../_templates/networking/security/nacl/ingress"

  # using created aws components from other modules  
  rule_number = 201
  protocol    = -1
  from_port   = 0
  to_port     = 65535
  cidr_block  = var.destination_cidr_block-vpc_c

  nacl_id = var.vpc_a-nacl_private_id
}
