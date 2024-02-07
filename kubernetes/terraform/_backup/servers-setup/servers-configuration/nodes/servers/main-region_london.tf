module "EC2-REGION_LONDON" {
  source = "./ec2-instance"
  providers = {
    aws = aws.l
  }

  count    = length(var.nodes.region_london.servers)
  tagname  = var.nodes.region_london.servers[count.index].tagname
  hostname = var.nodes.region_london.servers[count.index].hostname
  tag_path = var.namespace
}

module "KUBELET_PORT_ACCESS-REGION_LONDON" {
  source = "./kubelet_port_access"
  depends_on = [
    module.EC2-REGION_LONDON
  ]
  providers = {
    aws = aws.l
  }

  count     = length(module.EC2-REGION_LONDON)
  vpc_id    = module.EC2-REGION_LONDON[count.index].output-ec2-subnet.vpc_id
  subnet_id = module.EC2-REGION_LONDON[count.index].output-ec2-subnet.id
  eni_id    = module.EC2-REGION_LONDON[count.index].output-eni.id

  from_port   = var.nodes.ports.kubelet
  to_port     = var.nodes.ports.kubelet
  protocol    = "tcp"
  cidr_blocks = [var.control_plane-server1-ec2-subnet.cidr_block]

  tag_path    = var.namespace
  entity_name = "kubelet_port_access"
}
module "NODEPORT_ACCESS-REGION_LONDON" {
  source = "./nodeport_access"
  depends_on = [
    module.EC2-REGION_LONDON
  ]
  providers = {
    aws = aws.l
  }

  count     = length(module.EC2-REGION_LONDON)
  vpc_id    = module.EC2-REGION_LONDON[count.index].output-ec2-subnet.vpc_id
  subnet_id = module.EC2-REGION_LONDON[count.index].output-ec2-subnet.id
  eni_id    = module.EC2-REGION_LONDON[count.index].output-eni.id

  from_port   = var.nodes.ports.nodeport.from_port
  to_port     = var.nodes.ports.nodeport.to_port
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  tag_path    = var.namespace
  entity_name = "nodeport_access"
}
