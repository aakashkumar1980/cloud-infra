module "VPC_C-SECURITYGROUP-CREATE" {
  source = "./securitygroup-create"

  tag_path          = "${var.ns}.vpc_c"
  vpc_id            = var.vpc_c.id
  ingress-rules_map = var.ingress-rules_map
}

module "VPC_C-EC2" {
  source = "./ec2"

  vpc_c-subnet_private = var.vpc_c-subnet_private
  security_group_ids   = [module.VPC_C-SECURITYGROUP-CREATE.output-sg.id, var.vpc_c-sg_private.id]

  ami                  = var.ami
  instance_type        = var.instance_type
  keypair              = var.keypair
  iam_instance_profile = var.iam_instance_profile

  tag_path              = var.ns
  entity_name-primary   = var.entity_name-primary
  entity_name-secondary = var.entity_name-secondary
}

