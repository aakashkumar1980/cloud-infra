module "VPC_A-SECURITYGROUP-CREATE" {
  source = "./securitygroup-create"

  ns                = var.ns
  vpc_id            = var.vpc_a.id
  vpc_name          = "vpc_a"
  ingress-rules_map = var.ingress-rules_map
}

module "VPC_B-SECURITYGROUP-CREATE" {
  source = "./securitygroup-create"

  ns                = var.ns
  vpc_id            = var.vpc_b.id
  vpc_name          = "vpc_b"
  ingress-rules_map = var.ingress-rules_map
}


