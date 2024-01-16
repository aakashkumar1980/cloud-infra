/** ******** **/
/** VPC_LEFT **/
/** ******** **/
module "ROUTES-VPC_LEFT" {
  source = "../../../../../../../../_templates/networking/routetable/routes/_site2site-connection/vpc-peering"

  peering_id = var.peering_remote_requester_id-vpc_right2left

  destination_cidr_block = var.destination_cidr_block-vpc_left
  routetable_id          = var.routetable_id

}

/** ********** **/
/** VPC_CENTER **/
/** ********** **/
module "ROUTES-VPC_CENTER" {
  source = "../../../../../../../../_templates/networking/routetable/routes/_site2site-connection/vpc-peering"

  peering_id = var.peering_remote_requester_id-vpc_right2center

  destination_cidr_block = var.destination_cidr_block-vpc_center
  routetable_id          = var.routetable_id

}
