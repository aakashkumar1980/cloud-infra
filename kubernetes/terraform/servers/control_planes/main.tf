module "VPC_C-SECURITYGROUP-CREATE" {
  source = "./securitygroup-create"

  ns                = var.ns
  vpc_id            = var.vpc_c.id
  vpc_name          = "vpc_c"
  ingress-rules_map = var.ingress-rules_map
}


