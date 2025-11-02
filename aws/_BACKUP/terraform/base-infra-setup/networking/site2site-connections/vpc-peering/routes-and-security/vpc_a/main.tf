module "SECURITYGROUP-UPDATE" {
  source = "./securitygroup-update"
  providers = {
    aws = aws.rg
  }
  ingress-rules_map            = var.ingress-rules_map
  vpc_a-sg_private_id          = data.aws_security_group.vpc_a-sg_private.id

  destination_cidr_block-vpc_b = data.aws_vpc.vpc_b.cidr_block
  destination_cidr_block-vpc_c = data.aws_vpc.vpc_c.cidr_block
}

module "NACL-UPDATE" {
  source = "./nacl-update"
  providers = {
    aws = aws.rg
  }
  ingress-rules_map            = var.ingress-rules_map
  vpc_a-nacl_private_id        = tolist(data.aws_network_acls.vpc_a-nacl_private.ids)[0]

  destination_cidr_block-vpc_b = data.aws_vpc.vpc_b.cidr_block
  destination_cidr_block-vpc_c = data.aws_vpc.vpc_c.cidr_block
}

module "ROUTETABLE-UPDATE" {
  source = "./routetable-update"
  providers = {
    aws = aws.rg
  }
  vpc_a-rt_private_id = data.aws_route_table.vpc_a-rt_private.id

  peering_local-vpc_a2b_id     = var.peering_local-vpc_a2b.id
  destination_cidr_block-vpc_b = data.aws_vpc.vpc_b.cidr_block
  peering_remote-vpc_a2c_id    = var.peering_remote_requester-vpc_a2c.id
  destination_cidr_block-vpc_c = data.aws_vpc.vpc_c.cidr_block
}
