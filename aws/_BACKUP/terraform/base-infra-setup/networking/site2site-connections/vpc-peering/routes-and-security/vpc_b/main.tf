module "SECURITYGROUP-UPDATE" {
  source = "./securitygroup-update"
  providers = {
    aws = aws.rg
  }
  ingress-rules_map            = var.ingress-rules_map
  vpc_b-sg_private_id          = data.aws_security_group.vpc_b-sg_private.id

  destination_cidr_block-vpc_a = data.aws_vpc.vpc_a.cidr_block
  destination_cidr_block-vpc_c = data.aws_vpc.vpc_c.cidr_block
}

module "NACL-UPDATE" {
  source = "./nacl-update"
  providers = {
    aws = aws.rg
  }
  ingress-rules_map            = var.ingress-rules_map
  vpc_b-nacl_private_id        = tolist(data.aws_network_acls.vpc_b-nacl_private.ids)[0]

  destination_cidr_block-vpc_a = data.aws_vpc.vpc_a.cidr_block
  destination_cidr_block-vpc_c = data.aws_vpc.vpc_c.cidr_block
}

module "ROUTETABLE-UPDATE" {
  source = "./routetable-update"
  providers = {
    aws = aws.rg
  }
  vpc_b-rt_private_id = data.aws_route_table.vpc_b-rt_private.id

  peering_local-vpc_a2b_id     = var.peering_local-vpc_a2b.id
  destination_cidr_block-vpc_a = data.aws_vpc.vpc_a.cidr_block
  peering_remote-vpc_b2c_id    = var.peering_remote_requester-vpc_b2c.id
  destination_cidr_block-vpc_c = data.aws_vpc.vpc_c.cidr_block
}
