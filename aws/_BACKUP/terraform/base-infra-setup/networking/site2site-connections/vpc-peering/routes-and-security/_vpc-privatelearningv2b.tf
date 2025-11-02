/** VPC_B */
data "aws_vpc" "vpc_b" {
  provider = aws.rnvg
  filter {
    name   = "tag:Name"
    values = ["${var.ns}.vpc_b"]
  }
}

/** PRIVATELEARNINGV2 */
data "aws_vpc_peering_connection" "vpc_b-peering_connection" {
  provider = aws.rncf
  filter {
    name   = "tag:Name"
    values = ["${var.ns}.vpc_peering_remote.vpc-privatelearningv2b-requester"]
  }
}
/** PRIVATELEARNINGV2 :: RouteTable */
// NOTE: Please make sure that the subnets are attached to this route table (via. AWS Console). Do it manually if not.
module "ROUTES-VPC_PRIVATELEARNINGV2B" {
  source = "../../../../../_templates/networking/routetable/routes/site2site-connections/vpc-peering"
  providers = {
    aws = aws.rncf
  }
  peering_id = data.aws_vpc_peering_connection.vpc_b-peering_connection.id

  destination_cidr_block = data.aws_vpc.vpc_b.cidr_block
  routetable_id          = data.aws_route_table.rt_privatelearningv2.id
}
/** PRIVATELEARNINGV2 :: SecurityGroup */
// Not needed as it is already public