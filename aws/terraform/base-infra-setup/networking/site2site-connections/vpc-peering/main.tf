module "LOCAL" {
  source = "./local"
  providers = {
    aws = aws.rgn_nvg
  }

  ns = var.ns
}

module "REMOTE" {
  source = "./remote"
  providers = {
    aws.rnvg = aws.rgn_nvg
    aws.rldn = aws.rgn_ldn
  }

  ns = var.ns
}
