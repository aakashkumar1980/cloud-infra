module "SERVER1" {
  source = "./server1"
  providers = {
    aws = aws.rn
  }

  server    = var.control_planes.server1
  namespace = var.namespace
}
