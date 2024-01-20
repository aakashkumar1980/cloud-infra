module "SECURITYGROUP-UPDATE" {
  source = "./securitygroup-update"

  ingress-rules_map            = var.ingress-rules_map
  securitygroup_id-vpc_a       = var.securitygroup_id-vpc_a
  destination_cidr_block-vpc_b = var.destination_cidr_block-vpc_b
}
