/** ******** **/
/** VPC_LEFT **/
/** ******** **/
module "NACL_INGRESS-VPC_LEFT" {
  source = "../../../../../../../../_templates/networking/_firewall/nacl/ingress"

  count  = length(var.ingress-rules_map)
  # using created aws components from other modules  
  rule_number = 360+count.index
  protocol    = element(var.ingress-rules_map, count.index).protocol
  from_port   = element(var.ingress-rules_map, count.index).from_port
  to_port     = element(var.ingress-rules_map, count.index).to_port
  cidr_block  = var.destination_cidr_block-vpc_left

  nacl_id = var.nacl_id
}

/** ********** **/
/** VPC_CENTER **/
/** ********** **/
module "NACL_INGRESS-VPC_CENTER" {
  source = "../../../../../../../../_templates/networking/_firewall/nacl/ingress"

  count  = length(var.ingress-rules_map)
  # using created aws components from other modules  
  rule_number = 370+count.index
  protocol    = element(var.ingress-rules_map, count.index).protocol
  from_port   = element(var.ingress-rules_map, count.index).from_port
  to_port     = element(var.ingress-rules_map, count.index).to_port
  cidr_block  = var.destination_cidr_block-vpc_center

  nacl_id = var.nacl_id
}

