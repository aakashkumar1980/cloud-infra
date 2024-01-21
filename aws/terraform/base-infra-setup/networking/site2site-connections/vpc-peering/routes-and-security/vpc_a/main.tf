module "SECURITYGROUP-UPDATE" {
  source = "./securitygroup-update"

  ingress-rules_map            = var.ingress-rules_map
  securitygroup_id-vpc_a       = data.aws_security_group.vpc_a_sg_private.id
  destination_cidr_block-vpc_b = data.aws_vpc.vpc_b.cidr_block
}
