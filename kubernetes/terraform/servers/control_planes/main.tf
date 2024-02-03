module "SECURITYGROUP-CREATE" {
  source = "./securitygroup-create"

  for_each          = var.cluster
  tag_path          = "${var.ns}.${each.value.vpc}.${each.value.type}"
  vpc_id            = "${each.value.vpc}" == "vpc_a" ? var.vpc_a.id : var.vpc_b.id
  ingress-rules_map = var.ingress-rules_map
}

module "EC2" {
  source = "./ec2"

  for_each  = var.cluster
  subnet_id = "${each.value.vpc}" == "vpc_a" ? var.vpc_a-subnet_private.id : var.vpc_b-subnet_private.id
  security_groups = [
    "${each.value.vpc}" == "vpc_a" ? var.vpc_a-sg_private.id : var.vpc_b-sg_private.id,
    module.SECURITYGROUP-CREATE["${each.value.type}"].output-sg.id
  ]

  ami                  = var.ami
  instance_type        = var.instance_type
  keypair              = var.keypair
  iam_instance_profile = var.iam_instance_profile
  user_data            = var.user_data

  tag_path    = "${var.ns}.${each.value.vpc}.${each.value.type}"
  entity_name = each.value.type
}

