/** PRIVATELEARNINGV2 **/
data "aws_instance" "ec2_privatelearningv2" {
  provider = aws.rf

  filter {
    name   = "tag:Name"
    values = ["PrivateLearningV2"]
  }
}
data "aws_subnet" "subnet_privatelearningv2" {
  provider = aws.rf
  id = data.aws_instance.ec2_privatelearningv2.subnet_id
}

data "aws_region" "vpc_a-region" {
  provider = aws.rg
}

/** PRIVATELEARNINGV2-VPC_A **/
/** REQUESTER **/
module "PEERING-VPC_PRIVATELEARNINGV2A" {
  source = "../../../../../../_templates/networking/site2site-connections/vpc-peering/remote/requester"
  providers = {
    aws = aws.rf
  }
  vpc_id      = data.aws_subnet.subnet_privatelearningv2.vpc_id
  peer_vpc_id = var.vpc_a.id
  peer_region = data.aws_region.vpc_a-region.name

  tag_path    = var.ns
  entity_name = "vpc-privatelearningv2a"
}
/** ACCEPTER **/
module "PEERING-VPC_A2PRIVATELEARNINGV2" {
  source = "../../../../../../_templates/networking/site2site-connections/vpc-peering/remote/accepter"
  providers = {
    aws = aws.rg
  }
  peering_id = module.PEERING-VPC_PRIVATELEARNINGV2A.output-vpc_peering_connection-request.id

  tag_path    = var.ns
  entity_name = "vpc-a2privatelearningv2"
}

