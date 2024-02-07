module "SG" {
  source = "../../../../aws/terraform/_templates/security/securitygroup"

  vpc_id      = var.vpc_a.id
  tag_path    = "${var.ns}.vpc_a"
  entity_name = "efs"
}

module "SG-INGRESS_RULES" {
  source = "../../../../aws/terraform/_templates/security/securitygroup/ingress"

  from_port   = 2049
  to_port     = 2049
  protocol    = "tcp"
  cidr_blocks = [var.vpc_a.cidr_block, var.vpc_b.cidr_block]

  securitygroup_id = module.SG.output-sg.id
}

