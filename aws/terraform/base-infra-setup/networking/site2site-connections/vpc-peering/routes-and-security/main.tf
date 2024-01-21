module "VPC_A" {
  source = "./vpc_a"
  providers = {
    aws = aws.rnvg
  }

  ns                = var.ns
  ingress-rules_map = var.ingress-rules_map
}
