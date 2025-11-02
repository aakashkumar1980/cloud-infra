data "aws_region" "vpc_b-region" {
  provider = aws.rg
}

/** PRIVATELEARNINGV2-VPC_B **/
/** REQUESTER **/
module "PEERING-VPC_PRIVATELEARNINGV2B" {
  source = "../../../../../../_templates/networking/site2site-connections/vpc-peering/remote/requester"
  providers = {
    aws = aws.rf
  }
  vpc_id      = data.aws_subnet.subnet_privatelearningv2.vpc_id
  peer_vpc_id = var.vpc_b.id
  peer_region = data.aws_region.vpc_b-region.name

  tag_path    = var.ns
  entity_name = "vpc-privatelearningv2b"
}
/** ACCEPTER **/
module "PEERING-VPC_B2PRIVATELEARNINGV2" {
  source = "../../../../../../_templates/networking/site2site-connections/vpc-peering/remote/accepter"
  providers = {
    aws = aws.rg
  }
  peering_id = module.PEERING-VPC_PRIVATELEARNINGV2B.output-vpc_peering_connection-request.id

  tag_path    = var.ns
  entity_name = "vpc-b2privatelearningv2"
}
