module "EFS" {
  source = "../../../../aws/terraform/_templates/storage/efs"

  subnet_id       = vpc_a-subnet_private.id
  security_groups = [module.SG.output-sg.id]
  entity_name     = "${var.ns}.vpc_a"
  tag_path        = "efs"
}
