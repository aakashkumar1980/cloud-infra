module "PEERING_CONNECTIONS" {
  source = "./peering-connections"
  providers = {
    aws.rnvg = aws.rgn_nvg
    aws.rldn = aws.rgn_ldn
  }

  ns = var.ns
}

module "ROUTES_AND_SECURITY" {
  source = "./routes-and-security"
  providers = {
    aws.rnvg = aws.rgn_nvg
    aws.rldn = aws.rgn_ldn
  }

  ns                = var.ns
  ingress-rules_map = var.ingress-rules_map
}

