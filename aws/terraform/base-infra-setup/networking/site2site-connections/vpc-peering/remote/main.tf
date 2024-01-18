module "PEERING-VPC_A2C" {
  source = "../../../../../_templates/networking/site2site-connections/vpc-peering/remote/requester"
  providers = {
    aws = aws.rnvg
  }

  vpc_id      = data.aws_vpc.vpc_a.id
  peer_vpc_id = data.aws_vpc.vpc_c.id
  peer_region = data.aws_region.vpc_c-region.name

  tag_path    = var.ns
  entity_name = "vpc-a2c"
}
