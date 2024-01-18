module "PEERING-VPC_A2B" {
  source = "../../../../../_templates/networking/site2site-connections/vpc-peering/local"

  vpc_id      = data.aws_vpc.vpc_a.id
  peer_vpc_id = data.aws_vpc.vpc_b.id

  tag_path    = var.ns
  entity_name = "vpc_a2b"
}
