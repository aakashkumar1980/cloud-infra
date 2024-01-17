module "PEERING-VPC_B2A" {
  source = "../../../../../../_templates/networking/site2site-connections/vpc-peering/local"

  vpc_id      = data.aws_vpc.vpc_b.id
  peer_vpc_id = data.aws_vpc.vpc_a.id

  tag_path    = "${var.ns}.vpc-peering"
  entity_name = "local-b2a"
}
