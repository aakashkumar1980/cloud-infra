module "EC2-INSTANCE" {
  source = "./ec2-instance"

  tagname  = var.server.tagname
  hostname = var.server.hostname
  tag_path = var.namespace
}

module "API_SERVER_PORT-ACCESS" {
  source = "./api_server_port-access"
  depends_on = [
    module.EC2-INSTANCE
  ]

  vpc_id    = module.EC2-INSTANCE.output-ec2-subnet.vpc_id
  subnet_id = module.EC2-INSTANCE.output-ec2-subnet.id
  eni_id    = module.EC2-INSTANCE.output-eni.id

  from_port = var.server.ports.api_server
  to_port   = var.server.ports.api_server
  protocol  = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  tag_path    = var.namespace
  entity_name = "api_server_port-access"
}
