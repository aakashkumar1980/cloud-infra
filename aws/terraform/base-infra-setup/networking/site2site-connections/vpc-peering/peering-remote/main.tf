/*****************/
/** VPC-PEERING **/
/*****************/
module "PEERING_REMOTE_REQUESTER-VPC_PRIVATELEARNINGV2CENTER" {
  source = "../../../../../../_templates/networking/_site2site-connection/vpc-peering/remote/requester"
  providers = {
    aws = aws.mum
  }

  vpc_id      = var.vpc_id-vpc_privatelearningv2
  peer_vpc_id = var.vpc_id-vpc_center
  peer_region = var.peer_region

  tag_path    = var.tag_path
  entity_name = "remote-vpc_privatelearningv2center"
}


module "PEERING_REMOTE_REQUESTER-VPC_RIGHT2LEFT" {
  source = "../../../../../../_templates/networking/_site2site-connection/vpc-peering/remote/requester"
  providers = {
    aws = aws.ldn
  }

  vpc_id      = var.vpc_id-vpc_right
  peer_vpc_id = var.vpc_id-vpc_left
  peer_region = var.peer_region

  tag_path    = var.tag_path
  entity_name = "remote-vpc_right2left"
}
module "PEERING_REMOTE_REQUESTER-VPC_RIGHT2CENTER" {
  source = "../../../../../../_templates/networking/_site2site-connection/vpc-peering/remote/requester"
  providers = {
    aws = aws.ldn
  }

  vpc_id      = var.vpc_id-vpc_right
  peer_vpc_id = var.vpc_id-vpc_center
  peer_region = var.peer_region

  tag_path    = var.tag_path
  entity_name = "remote-vpc_right2center"
}



/**********/
/** VPCs **/
/**********/
module "VPC_PRIVATELEARNINGV2" {
  source = "./_vpc-privatelearningv2"
  depends_on = [
    module.PEERING_REMOTE_REQUESTER-VPC_PRIVATELEARNINGV2CENTER
  ]
  providers = {
    aws = aws.mum
  }

  peering_id-vpc_privatelearningv2center = module.PEERING_REMOTE_REQUESTER-VPC_PRIVATELEARNINGV2CENTER.output-vpc_peering_connection-request.id

  routetable_id-vpc_privatelearningv2 = var.routetable_id-vpc_privatelearningv2
  destination_cidr_block-vpc_center   = var.cidr_block-vpc_center
}

module "VPC_RIGHT" {
  source = "./vpc_right"
  depends_on = [
    module.PEERING_REMOTE_REQUESTER-VPC_RIGHT2LEFT,
    module.PEERING_REMOTE_REQUESTER-VPC_RIGHT2CENTER
  ]
  providers = {
    aws = aws.ldn
  }

  peering_remote_requester_id-vpc_right2left   = module.PEERING_REMOTE_REQUESTER-VPC_RIGHT2LEFT.output-vpc_peering_connection-request.id
  peering_remote_requester_id-vpc_right2center = module.PEERING_REMOTE_REQUESTER-VPC_RIGHT2CENTER.output-vpc_peering_connection-request.id

  ingress-rules_map                 = var.ingress-rules_map
  destination_cidr_block-vpc_center = var.cidr_block-vpc_center
  destination_cidr_block-vpc_left   = var.cidr_block-vpc_left

  vpc_id        = var.vpc_id-vpc_right
  eni_id        = var.eni_id-vpc_right
  nacl_id       = var.nacl_id-vpc_right
  routetable_id = var.routetable_id-vpc_right

  tag_path = var.tag_path
}



