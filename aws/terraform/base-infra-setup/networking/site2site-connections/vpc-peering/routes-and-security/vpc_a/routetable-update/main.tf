module "ROUTES-VPC_B" {
  source = "../../../../../../../_templates/networking/routetable/routes/site2site-connections/vpc-peering"

  peering_id = var.peering_local-vpc_a2b_id

  destination_cidr_block = var.destination_cidr_block-vpc_b
  routetable_id          = var.vpc_a-rt_private_id
}

module "ROUTES-VPC_C" {
  source = "../../../../../../../_templates/networking/routetable/routes/site2site-connections/vpc-peering"

  peering_id = var.peering_remote-vpc_a2c_id

  destination_cidr_block = var.destination_cidr_block-vpc_c
  routetable_id          = var.vpc_a-rt_private_id
}
