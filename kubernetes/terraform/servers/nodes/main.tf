module "VPC_AB-SECURITYGROUP_CREATE" {
  source = "./securitygroup-create"

  for_each          = { for idx, vpc_info in var.vpc_ab : idx => vpc_info }
  tag_path          = "${var.ns}.${each.value.vpc}"
  vpc_id            = "${each.value.vpc}" == "vpc_a" ? var.vpc_a.id : var.vpc_b.id
  ingress-rules_map = var.ingress-rules_map
}

module "VPC_AB-EC2" {
  source = "./ec2"

  for_each              = { for idx, vpc_info in var.vpc_ab : idx => vpc_info }
  vpc_ab-subnet_private = "${each.value.vpc}" == "vpc_a" ? var.vpc_a-subnet_private : var.vpc_b-subnet_private

  security_group_ids = concat(
    [for sg_key, sg_value in module.VPC_AB-SECURITYGROUP_CREATE : sg_value.output-sg.id if sg_value.output-sg.vpc_id == (each.value.vpc == "vpc_a" ? var.vpc_a.id : var.vpc_b.id)],
    [each.value.vpc == "vpc_a" ? var.vpc_a-sg_private.id : var.vpc_b-sg_private.id]
  )

  ami                  = var.ami
  instance_type        = var.instance_type
  keypair              = var.keypair
  iam_instance_profile = var.iam_instance_profile
  user_data            = var.user_data

  tag_path    = "${var.ns}.${each.value.vpc}"
  entity_name = each.value.hostname
}

