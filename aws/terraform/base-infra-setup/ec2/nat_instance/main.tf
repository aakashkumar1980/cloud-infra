module "SECURITYGROUP" {
  source = "./securitygroup"

  vpc_id  = var.vpc_id
  subnets = var.subnets

  tag_path = var.tag_path
}

module "EC2" {
  source = "../../../_templates/ec2"
  depends_on = [
    module.SECURITYGROUP
  ]

  source_dest_check = false
  subnet_id = [
    for v in var.subnets : v.id if(
      (v.vpc_id == var.vpc_id)
      && (length(regexall("(.subnet_generic-)", v.tags["Name"])) != 0)
    )
  ][0]
  security_groups = [module.SECURITYGROUP.output-sg_nat.id]

  ami           = var.ami
  instance_type = var.instance_type
  keypair       = var.keypair.key_name

  tag_path = ([
    for v in var.subnets : "${v.tags["Name"]}" if(
      (v.vpc_id == var.vpc_id)
      && (length(regexall("(.subnet_generic-)", v.tags["Name"])) != 0)
    )
  ][0])
  entity_name = "natgateway-server"

}

module "ROUTE" {
  source = "./route"
  depends_on = [
    module.EC2
  ]

  route_table_id         = data.aws_route_table.route_table.id
  destination_cidr_block = "0.0.0.0/0"
  instance_id            = module.EC2.output-ec2.id
}
