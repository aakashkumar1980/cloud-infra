module "SECURITYGROUP-UPDATE" {
  source = "./securitygroup-update"

  ingress-rules_map            = var.ingress-rules_map
  vpc_a-sg_private_id          = data.aws_security_group.vpc_a-sg_private.id
  destination_cidr_block-vpc_b = data.aws_vpc.vpc_b.cidr_block
}

module "NACL-UPDATE" {
  source = "./nacl-update"

  ingress-rules_map            = var.ingress-rules_map
  vpc_a-nacl_private_id        = tolist(data.aws_network_acls.vpc_a-nacl_private.ids)[0]
  destination_cidr_block-vpc_b = data.aws_vpc.vpc_b.cidr_block
}

module "ROUTETABLE-UPDATE" {
  source = "./routetable-update"

  peering_local-vpc_a2b_id     = var.peering_local-vpc_a2b.id
  vpc_a-rt_private_id          = data.aws_route_table.vpc_a-rt_private.id
  destination_cidr_block-vpc_b = data.aws_vpc.vpc_b.cidr_block
}
