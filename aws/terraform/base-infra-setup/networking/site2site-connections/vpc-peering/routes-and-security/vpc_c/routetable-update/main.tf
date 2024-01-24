module "ROUTES-VPC_A" {
  source = "../../../../../../../_templates/networking/routetable/routes/site2site-connections/vpc-peering"

  peering_id = var.peering_remote_accepter-vpc_c2a_id

  destination_cidr_block = var.destination_cidr_block-vpc_a
  routetable_id          = var.vpc_c-rt_private_id
}

module "ROUTES-VPC_B" {
  source = "../../../../../../../_templates/networking/routetable/routes/site2site-connections/vpc-peering"

  peering_id = var.peering_remote_accepter-vpc_c2b_id

  destination_cidr_block = var.destination_cidr_block-vpc_b
  routetable_id          = var.vpc_c-rt_private_id
}
