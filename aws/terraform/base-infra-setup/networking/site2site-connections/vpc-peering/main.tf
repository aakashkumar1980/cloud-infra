module "PEERING" {
  source = "./peering"
  providers = {
    aws.rnvg = aws.reg_nvg
    aws.rldn = aws.reg_ldn
  }

  ns = var.ns
}
