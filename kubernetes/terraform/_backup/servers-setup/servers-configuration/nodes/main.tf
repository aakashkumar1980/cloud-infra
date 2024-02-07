module "SERVERS" {
  source = "./servers"
  providers = {
    aws.n = aws.rn
    aws.l = aws.rl
  }

  nodes                            = var.nodes
  control_plane-server1-ec2-subnet = var.control_plane-server1-ec2-subnet
  namespace                        = var.namespace
}
