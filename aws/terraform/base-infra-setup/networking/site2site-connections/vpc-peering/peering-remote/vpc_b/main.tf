module "ROUTETABLE-UPDATE" {
  source = "./routetable-update"

  peering_id-vpc_privatelearningv2center = var.peering_id-vpc_privatelearningv2center
  destination_cidr_block-vpc_center      = var.destination_cidr_block-vpc_center
  routetable_id                          = var.routetable_id-vpc_privatelearningv2

}

