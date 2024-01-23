module "VPC_A" {
  source = "./vpc_a"
  providers = {
    aws = aws.rnvg
  }

  peering_local-vpc_a2b = var.peering_local-vpc_a2b

  ns                = var.ns
  ingress-rules_map = var.ingress-rules_map
}
