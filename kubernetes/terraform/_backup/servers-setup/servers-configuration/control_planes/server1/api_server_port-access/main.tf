module "SECURITYGROUP" {
  source = "../../../../../../../../aws/aws_certified_solutions_architect/_templates/networking/_firewall/securitygroup"

  vpc_id = var.vpc_id

  tag_path    = var.tag_path
  entity_name = var.entity_name
}
module "SECURITYGROUP-INGRESS" {
  source = "../../../../../../../../aws/aws_certified_solutions_architect/_templates/networking/_firewall/securitygroup/ingress"

  from_port   = var.from_port
  to_port     = var.to_port
  protocol    = var.protocol
  cidr_blocks = var.cidr_blocks

  securitygroup_id = module.SECURITYGROUP.output-sg.id
}
module "SECURITYGROUP-ATTACH_EC2" {
  source = "../../../../../../../../aws/aws_certified_solutions_architect/_templates/networking/_firewall/securitygroup/ec2"

  securitygroup_id = module.SECURITYGROUP.output-sg.id
  eni_id           = var.eni_id
}


module "NACL-INGRESS" {
  source = "../../../../../../../../aws/aws_certified_solutions_architect/_templates/networking/_firewall/nacl/ingress"

  rule_number = 200
  protocol    = var.protocol
  from_port   = var.from_port
  to_port     = var.to_port
  cidr_block  = join("",var.cidr_blocks)

  nacl_id = join("", data.aws_network_acls.selected-nacl.ids)

}


