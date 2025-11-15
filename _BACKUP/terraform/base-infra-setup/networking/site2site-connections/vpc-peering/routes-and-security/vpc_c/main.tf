module "SECURITYGROUP-UPDATE" {
  source = "securitygroup-update"
  providers = {
    aws = aws.rn
  }
  ingress-rules_map            = var.ingress-rules_map
  vpc_c-sg_private_id          = data.aws_security_group.vpc_c-sg_private.id

  destination_cidr_block-vpc_a = data.aws_vpc.vpc_a.cidr_block
  destination_cidr_block-vpc_b = data.aws_vpc.vpc_b.cidr_block
}

module "NACL-UPDATE" {
  source = "nacl-update"
  providers = {
    aws = aws.rn
  }
  ingress-rules_map            = var.ingress-rules_map
  vpc_c-nacl_private_id        = tolist(data.aws_network_acls.vpc_c-nacl_private.ids)[0]

  destination_cidr_block-vpc_a = data.aws_vpc.vpc_a.cidr_block
  destination_cidr_block-vpc_b = data.aws_vpc.vpc_b.cidr_block
}

module "ROUTETABLE-UPDATE" {
  source = "routetable-update"
  providers = {
    aws = aws.rn
  }
  vpc_c-rt_private_id = data.aws_route_table.vpc_c-rt_private.id

  peering_remote_accepter-vpc_c2a_id = var.peering_remote_accepter-vpc_c2a.id
  destination_cidr_block-vpc_a       = data.aws_vpc.vpc_a.cidr_block
  peering_remote_accepter-vpc_c2b_id = var.peering_remote_accepter-vpc_c2b.id
  destination_cidr_block-vpc_b       = data.aws_vpc.vpc_b.cidr_block
}
