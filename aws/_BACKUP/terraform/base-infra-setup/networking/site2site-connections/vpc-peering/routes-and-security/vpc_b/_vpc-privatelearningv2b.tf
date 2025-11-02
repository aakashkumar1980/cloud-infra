/** PRIVATELEARNINGV2 */
data "aws_instance" "ec2_privatelearningv2" {
  provider = aws.rf

  filter {
    name   = "tag:Name"
    values = ["PrivateLearningV2"]
  }
}
data "aws_subnet" "subnet_privatelearningv2" {
  provider = aws.rf
  id       = data.aws_instance.ec2_privatelearningv2.subnet_id
}


/** VPC_B */
data "aws_vpc_peering_connection" "vpc_b-peering_connection" {
  provider = aws.rg
  filter {
    name   = "tag:Name"
    values = ["${var.ns}.vpc_peering_remote.vpc-b2privatelearningv2-accepter"]
  }
}
/** VPC_B :: SecurityGroup */
module "SECURITYGROUP-INGRESS-VPC_B2PRIVATELEARNINGV2" {
  source = "../../../../../../_templates/security/securitygroup/ingress"
  providers = {
    aws = aws.rg
  }

  count = length(var.ingress-rules_map)
  # using created aws components from other modules
  protocol    = element(var.ingress-rules_map, count.index).protocol
  from_port   = element(var.ingress-rules_map, count.index).from_port
  to_port     = element(var.ingress-rules_map, count.index).to_port
  description = element(var.ingress-rules_map, count.index).description
  cidr_blocks = [data.aws_subnet.subnet_privatelearningv2.cidr_block]

  securitygroup_id = data.aws_security_group.vpc_b-sg_private.id
}
/** VPC_B : NACL */
module "NACL-INGRESS-VPC_B2PRIVATELEARNINGV2" {
  source = "../../../../../../_templates/networking/security/nacl/ingress"
  providers = {
    aws = aws.rg
  }

  # using created aws components from other modules
  rule_number = 202
  protocol    = -1
  from_port   = 0
  to_port     = 65535
  cidr_block  = data.aws_subnet.subnet_privatelearningv2.cidr_block

  nacl_id = tolist(data.aws_network_acls.vpc_b-nacl_private.ids)[0]
}

/** VPC_B :: RouteTable */
module "ROUTES-VPC_B2PRIVATELEARNINGV2" {
  source = "../../../../../../_templates/networking/routetable/routes/site2site-connections/vpc-peering"
  providers = {
    aws = aws.rg
  }
  peering_id = data.aws_vpc_peering_connection.vpc_b-peering_connection.id

  destination_cidr_block = data.aws_subnet.subnet_privatelearningv2.cidr_block
  routetable_id          = data.aws_route_table.vpc_b-rt_private.id
}