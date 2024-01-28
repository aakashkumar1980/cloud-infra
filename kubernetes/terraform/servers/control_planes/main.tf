module "SECURITYGROUP-CREATE" {
  source = "./securitygroup-create"
  providers = {
    aws.rnvg = aws.rgn_nvg
    aws.rldn = aws.rgn_ldn
  }

  ns                 = var.ns
  primary_vpc_name   = var.cp.cluster.primary.vpc
  primary_vpc        = var.cp.cluster.primary.vpc == "vpc_a" ? var.vpc_a : var.cp.cluster.primary.vpc == "vpc_b" ? var.vpc_b : var.vpc_c
  secondary_vpc_name = var.cp.cluster.secondary.vpc
  secondary_vpc      = var.cp.cluster.secondary.vpc == "vpc_a" ? var.vpc_a : var.cp.cluster.secondary.vpc == "vpc_b" ? var.vpc_b : var.vpc_c

  ingress-rules_map = var.ingress-rules_map
}
