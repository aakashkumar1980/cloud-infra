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

data "aws_vpc" "vpc_a" {
  provider = aws.rnvg
  filter {
    name   = "tag:Name"
    values = ["${var.ns}.vpc_a"]
  }
}


/** RouteTable */
module "ROUTES-VPC_PRIVATELEARNINGV2" {
  source = "../../../../../_templates/networking/routetable/routes/site2site-connections/vpc-peering"
  providers = {
    aws = aws.rncf
  }

  peering_id = data.aws_vpc_peering_connection.vpc_a-peering_connection.id

  destination_cidr_block = data.aws_vpc.vpc_a.cidr_block
  routetable_id          = data.aws_route_table.rt_privatelearningv2.id
}