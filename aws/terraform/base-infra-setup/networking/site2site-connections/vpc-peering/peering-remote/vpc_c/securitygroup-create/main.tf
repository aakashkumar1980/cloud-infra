/** ******** **/
/** VPC_LEFT **/
/** ******** **/
module "SECURITYGROUP-VPC_LEFT" {
  source = "../../../../../../../../_templates/networking/_firewall/securitygroup"

  vpc_id = var.vpc_id

  tag_path    = var.tag_path
  entity_name = "left2right"
}
module "SECURITYGROUP-INGRESS-VPC_LEFT" {
  source = "../../../../../../../../_templates/networking/_firewall/securitygroup/ingress"
  depends_on = [
    module.SECURITYGROUP-VPC_LEFT
  ]

  count = length(var.ingress-rules_map)
  # using created aws components from other modules  
  protocol    = element(var.ingress-rules_map, count.index).protocol
  from_port   = element(var.ingress-rules_map, count.index).from_port
  to_port     = element(var.ingress-rules_map, count.index).to_port
  cidr_blocks = [var.destination_cidr_block-vpc_left]

  securitygroup_id = module.SECURITYGROUP-VPC_LEFT.output-sg.id
}
module "EC2-ATTACH-VPC_LEFT" {
  source = "../../../../../../../../_templates/networking/_firewall/securitygroup/ec2"
  depends_on = [
    module.SECURITYGROUP-VPC_LEFT
  ]

  securitygroup_id = module.SECURITYGROUP-VPC_LEFT.output-sg.id
  eni_id           = var.eni_id
}

/** ********** **/
/** VPC_CENTER **/
/** ********** **/
module "SECURITYGROUP-VPC_CENTER" {
  source = "../../../../../../../../_templates/networking/_firewall/securitygroup"

  vpc_id = var.vpc_id

  tag_path    = var.tag_path
  entity_name = "center2right"
}
module "SECURITYGROUP-INGRESS-VPC_CENTER" {
  source = "../../../../../../../../_templates/networking/_firewall/securitygroup/ingress"
  depends_on = [
    module.SECURITYGROUP-VPC_CENTER
  ]

  count = length(var.ingress-rules_map)
  # using created aws components from other modules  
  protocol    = element(var.ingress-rules_map, count.index).protocol
  from_port   = element(var.ingress-rules_map, count.index).from_port
  to_port     = element(var.ingress-rules_map, count.index).to_port
  cidr_blocks = [var.destination_cidr_block-vpc_center]

  securitygroup_id = module.SECURITYGROUP-VPC_CENTER.output-sg.id
}
module "EC2-ATTACH-VPC_CENTER" {
  source = "../../../../../../../../_templates/networking/_firewall/securitygroup/ec2"
  depends_on = [
    module.SECURITYGROUP-VPC_CENTER
  ]

  securitygroup_id = module.SECURITYGROUP-VPC_CENTER.output-sg.id
  eni_id           = var.eni_id
}
