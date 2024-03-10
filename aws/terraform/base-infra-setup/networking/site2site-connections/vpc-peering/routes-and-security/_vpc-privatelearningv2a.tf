/** VPC_A */
data "aws_vpc" "vpc_a" {
  provider = aws.rnvg
  filter {
    name   = "tag:Name"
    values = ["${var.ns}.vpc_a"]
  }
}

/** PRIVATELEARNINGV2 */
data "aws_instance" "ec2_privatelearningv2" {
  provider = aws.rncf

  filter {
    name   = "tag:Name"
    values = ["PrivateLearningV2"]
  }
}
data "aws_subnet" "subnet_privatelearningv2" {
  provider = aws.rncf
  id       = data.aws_instance.ec2_privatelearningv2.subnet_id
}
data "aws_route_table" "rt_privatelearningv2" {
  provider  = aws.rncf
  subnet_id = data.aws_subnet.subnet_privatelearningv2.id
}
data "aws_vpc_peering_connection" "vpc_a-peering_connection" {
  provider = aws.rncf
  filter {
    name   = "tag:Name"
    values = ["${var.ns}.vpc_peering_remote.vpc-privatelearningv2a-requester"]
  }
}
/** PRIVATELEARNINGV2 :: RouteTable */
// NOTE: Please make sure that the subnets are attached to this route table (via. AWS Console). Do it manually if not.
module "ROUTES-VPC_PRIVATELEARNINGV2A" {
  source = "../../../../../_templates/networking/routetable/routes/site2site-connections/vpc-peering"
  providers = {
    aws = aws.rncf
  }
  peering_id = data.aws_vpc_peering_connection.vpc_a-peering_connection.id

  destination_cidr_block = data.aws_vpc.vpc_a.cidr_block
  routetable_id          = data.aws_route_table.rt_privatelearningv2.id
}
/** PRIVATELEARNINGV2 :: SecurityGroup */
// Not needed as it is already public