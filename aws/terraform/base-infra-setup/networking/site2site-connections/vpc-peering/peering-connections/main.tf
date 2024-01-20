module "LOCAL" {
  source = "./local"
  providers = {
    aws = aws.rnvg
  }

  ns    = var.ns
  vpc_a = data.aws_vpc.vpc_a
  vpc_b = data.aws_vpc.vpc_b
}

module "REMOTE" {
  source = "./remote"
  providers = {
    aws.rg = aws.rnvg
    aws.rn = aws.rldn
  }

  ns           = var.ns
  vpc_a        = data.aws_vpc.vpc_a
  vpc_b        = data.aws_vpc.vpc_b
  vpc_c        = data.aws_vpc.vpc_c
  vpc_c-region = data.aws_region.vpc_c-region
}

