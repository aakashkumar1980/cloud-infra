module "LOCAL" {
  source = "./local"
  providers = {
    aws = aws.rnvg
  }

  ns = var.ns
}
