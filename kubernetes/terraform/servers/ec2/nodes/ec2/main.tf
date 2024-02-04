module "EC2" {
  source = "../../../../../../aws/terraform/_templates/ec2"

  subnet_id       = var.vpc_b-subnet_private.id
  security_groups = var.security_group_ids
  user_data       = var.user_data

  ami                  = var.ami
  instance_type        = var.instance_type
  keypair              = var.keypair
  iam_instance_profile = var.iam_instance_profile

  tag_path    = var.tag_path
  entity_name = var.entity_name
}
