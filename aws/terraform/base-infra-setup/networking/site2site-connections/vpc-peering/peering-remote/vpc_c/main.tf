module "NACL-UPDATE" {
  source = "./nacl-update"

  ingress-rules_map = [
    # ping: skip as it is already added to the private_nacl
    for v in var.ingress-rules_map : v if(v.protocol != "icmp")
  ]

  destination_cidr_block-vpc_left   = var.destination_cidr_block-vpc_left
  destination_cidr_block-vpc_center = var.destination_cidr_block-vpc_center
  nacl_id                           = var.nacl_id
}

module "ROUTETABLE-UPDATE" {
  source = "./routetable-update"

  peering_remote_requester_id-vpc_right2left   = var.peering_remote_requester_id-vpc_right2left
  peering_remote_requester_id-vpc_right2center = var.peering_remote_requester_id-vpc_right2center

  destination_cidr_block-vpc_left   = var.destination_cidr_block-vpc_left
  destination_cidr_block-vpc_center = var.destination_cidr_block-vpc_center
  routetable_id                     = var.routetable_id

}

module "SECURITYGROUP-CREATE" {
  source = "./securitygroup-create"

  ingress-rules_map = var.ingress-rules_map

  vpc_id                            = var.vpc_id
  destination_cidr_block-vpc_left   = var.destination_cidr_block-vpc_left
  destination_cidr_block-vpc_center = var.destination_cidr_block-vpc_center
  eni_id                            = var.eni_id

  tag_path = var.tag_path

}
