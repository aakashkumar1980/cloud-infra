/** ********** **/
/** VPC_CENTER **/
/** ********** **/
module "ROUTES-VPC_CENTER" {
  source = "../../../../../../../../_templates/networking/routetable/routes/_site2site-connection/vpc-peering"

  peering_id = var.peering_id-vpc_privatelearningv2center

  destination_cidr_block = var.destination_cidr_block-vpc_center
  routetable_id          = var.routetable_id

}
