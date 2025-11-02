module "VPC_A" {
  source = "./vpc_a"
  providers = {
    aws.rg = aws.rnvg
    aws.rn = aws.rldn
    aws.rf = aws.rncf
  }

  peering_local-vpc_a2b            = var.peering_local-vpc_a2b
  peering_remote_requester-vpc_a2c = var.peering_remote_requester-vpc_a2c

  ns                = var.ns
  ingress-rules_map = var.ingress-rules_map
}

module "VPC_B" {
  source = "./vpc_b"
  providers = {
    aws.rg = aws.rnvg
    aws.rn = aws.rldn
    aws.rf = aws.rncf
  }

  peering_local-vpc_a2b            = var.peering_local-vpc_a2b
  peering_remote_requester-vpc_b2c = var.peering_remote_requester-vpc_b2c

  ns                = var.ns
  ingress-rules_map = var.ingress-rules_map
}

module "VPC_C" {
  source = "./vpc_c"
  providers = {
    aws.rg = aws.rnvg
    aws.rn = aws.rldn
  }

  peering_remote_accepter-vpc_c2a = var.peering_remote_accepter-vpc_c2a
  peering_remote_accepter-vpc_c2b = var.peering_remote_accepter-vpc_c2b

  ns                = var.ns
  ingress-rules_map = var.ingress-rules_map
}

