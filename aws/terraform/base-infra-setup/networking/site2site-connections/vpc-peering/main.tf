module "PEERING_CONNECTIONS" {
  source = "./peering-connections"
  providers = {
    aws.rnvg = aws.rgn_nvg
    aws.rldn = aws.rgn_ldn
  }

  ns = var.ns
}

