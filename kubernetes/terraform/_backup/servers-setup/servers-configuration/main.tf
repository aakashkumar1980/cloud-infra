module "CONTROL_PLANES" {
  source = "./control_planes"
  providers = {
    aws.rn = aws.rnvg
    aws.rl = aws.rldn
  }

  control_planes = var.server.control_planes
  namespace      = var.namespace
}

module "NODES" {
  source = "./nodes"
  providers = {
    aws.rn = aws.rnvg
    aws.rl = aws.rldn
  }

  nodes                            = var.server.nodes
  control_plane-server1-ec2-subnet = module.CONTROL_PLANES.output-server1-ec2-subnet

  namespace = var.namespace
}
