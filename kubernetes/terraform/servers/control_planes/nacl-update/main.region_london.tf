module "NACL-PRIMARY_CONTROL_PLANE-INGRESS-REGION_LONDON" {
  source = "../../../../../aws/terraform/_templates/networking/security/nacl/ingress"
  providers = {
    aws = aws.rldn
  }

  count = var.primary_vpc_name == "vpc_c" ? length(local.flattened_ingress_rules) : 0
  # using created aws components from other modules  
  rule_number = 350 + count.index
  protocol    = local.flattened_ingress_rules[count.index].protocol
  from_port   = local.flattened_ingress_rules[count.index].from_port
  to_port     = local.flattened_ingress_rules[count.index].to_port
  cidr_block  = local.flattened_ingress_rules[count.index].cidr_block

  nacl_id = join("", var.primary_vpc-nacl_private.ids)
}

