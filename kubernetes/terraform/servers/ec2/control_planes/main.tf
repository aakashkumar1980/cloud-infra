module "SECURITYGROUP-CREATE" {
  source = "./securitygroup-create"

  tag_path = "${var.ns}.vpc_a"
  vpc_id   = var.vpc_a.id

  efs-output-sg         = var.efs-output-sg
  efs-ingress-rules_map = var.efs-ingress-rules_map
  ingress-rules_map     = var.ingress-rules_map
}

module "EC2" {
  source = "./ec2"

  for_each        = { for vpc in var.cluster.vpc_a : vpc.hostname => vpc }
  subnet_id       = var.vpc_a-subnet_private.id
  security_groups = [var.vpc_a-sg_private.id, module.SECURITYGROUP-CREATE.output-sg.id]

  ami                  = var.ami
  instance_type        = var.instance_type
  keypair              = var.keypair
  iam_instance_profile = var.iam_instance_profile
  user_data            = var.user_data

  tag_path    = "${var.ns}.vpc_a.${each.value.type}"
  entity_name = each.value.hostname
}

