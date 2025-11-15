/** REQUESTER **/
module "PEERING-VPC_A2C" {
  source = "../../../../../../_templates/networking/site2site-connections/vpc-peering/remote/requester"
  providers = {
    aws = aws.rg
  }

  vpc_id      = var.vpc_a.id
  peer_vpc_id = var.vpc_c.id
  peer_region = var.vpc_c-region.name

  tag_path    = var.ns
  entity_name = "vpc-a2c"
}

module "PEERING-VPC_B2C" {
  source = "../../../../../../_templates/networking/site2site-connections/vpc-peering/remote/requester"
  providers = {
    aws = aws.rg
  }

  vpc_id      = var.vpc_b.id
  peer_vpc_id = var.vpc_c.id
  peer_region = var.vpc_c-region.name

  tag_path    = var.ns
  entity_name = "vpc-b2c"
}


/** ACCEPTER **/
module "PEERING-VPC_C2A" {
  source = "../../../../../../_templates/networking/site2site-connections/vpc-peering/remote/accepter"
  providers = {
    aws = aws.rn
  }

  peering_id = module.PEERING-VPC_A2C.output-vpc_peering_connection-request.id

  tag_path    = var.ns
  entity_name = "vpc-c2a"
}

module "PEERING-VPC_C2B" {
  source = "../../../../../../_templates/networking/site2site-connections/vpc-peering/remote/accepter"
  providers = {
    aws = aws.rn
  }

  peering_id = module.PEERING-VPC_B2C.output-vpc_peering_connection-request.id

  tag_path    = var.ns
  entity_name = "vpc-c2b"
}

