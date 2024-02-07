module "SECURITYGROUP_CREATE" {
  source = "./securitygroup-create"

  tag_path = "${var.ns}.vpc_b"
  vpc_id   = var.vpc_b.id

  efs-output-sg         = var.efs-output-sg
  efs-ingress-rules_map = var.efs-ingress-rules_map
  ingress-rules_map     = var.ingress-rules_map
}

module "EC2" {
  source = "./ec2"

  for_each             = { for idx, vpc_info in var.cluster.vpc_b : idx => vpc_info }
  vpc_b-subnet_private = var.vpc_b-subnet_private
  security_group_ids   = [module.SECURITYGROUP_CREATE.output-sg.id, var.vpc_b-sg_private.id]

  ami                  = var.ami
  instance_type        = var.instance_type
  keypair              = var.keypair
  iam_instance_profile = var.iam_instance_profile
  user_data            = var.user_data

  tag_path    = "${var.ns}.vpc_b"
  entity_name = each.value.hostname
}

