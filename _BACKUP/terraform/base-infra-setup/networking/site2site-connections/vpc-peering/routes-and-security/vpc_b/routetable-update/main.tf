module "ROUTES-VPC_A" {
  source = "../../../../../../../_templates/networking/routetable/routes/site2site-connections/vpc-peering"

  peering_id = var.peering_local-vpc_a2b_id

  destination_cidr_block = var.destination_cidr_block-vpc_a
  routetable_id          = var.vpc_b-rt_private_id
}

module "ROUTES-VPC_C" {
  source = "../../../../../../../_templates/networking/routetable/routes/site2site-connections/vpc-peering"

  peering_id = var.peering_remote-vpc_b2c_id

  destination_cidr_block = var.destination_cidr_block-vpc_c
  routetable_id          = var.vpc_b-rt_private_id
}
