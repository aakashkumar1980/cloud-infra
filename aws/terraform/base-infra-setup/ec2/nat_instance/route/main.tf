module "EC2_INSTANCE" {
  source = "../../../../_templates/networking/routetable/routes/ec2-instance"

  route_table_id = var.route_table_id

  destination_cidr_block = var.destination_cidr_block
  instance_id            = var.instance_id
}
