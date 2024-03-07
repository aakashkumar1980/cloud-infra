data "aws_instance" "ec2_privatelearningv2" {
  provider = aws.rnf

  filter {
    name   = "tag:Name"
    values = ["PrivateLearningV2"]
  }
}
data "aws_subnet" "subnet_privatelearningv2" {
  provider = aws.rnf
  id       = data.aws_instance.ec2_privatelearningv2.subnet_id
}
data "aws_vpc_peering_connection" "vpc_a-peering_connection" {
  provider = aws.rn
  filter {
    name   = "tag:Name"
    values = ["${var.ns}.vpc_peering_remote.vpc-a2privatelearningv2-accepter"]
  }
}

/** SecurityGroup */
module "SECURITYGROUP-INGRESS-VPC_PRIVATELEARNINGV2" {
  source = "../../../../../../_templates/security/securitygroup/ingress"
  providers = {
    aws = aws.rn
  }

  count = length(var.ingress-rules_map)
  # using created aws components from other modules
  protocol    = element(var.ingress-rules_map, count.index).protocol
  from_port   = element(var.ingress-rules_map, count.index).from_port
  to_port     = element(var.ingress-rules_map, count.index).to_port
  description = element(var.ingress-rules_map, count.index).description
  cidr_blocks = [data.aws_subnet.subnet_privatelearningv2.cidr_block]

  securitygroup_id = data.aws_security_group.vpc_a-sg_private.id
}
/** NACL */
module "NACL-INGRESS-VPC_PRIVATELEARNINGV2" {
  source = "../../../../../../_templates/networking/security/nacl/ingress"
  providers = {
    aws = aws.rn
  }

  # using created aws components from other modules
  rule_number = 202
  protocol    = -1
  from_port   = 0
  to_port     = 65535
  cidr_block  = data.aws_subnet.subnet_privatelearningv2.cidr_block

  nacl_id = tolist(data.aws_network_acls.vpc_a-nacl_private.ids)[0]
}

/** RouteTable */
module "ROUTES-VPC_PRIVATELEARNINGV2" {
  source = "../../../../../../_templates/networking/routetable/routes/site2site-connections/vpc-peering"
  providers = {
    aws = aws.rn
  }

  peering_id = data.aws_vpc_peering_connection.vpc_a-peering_connection.id

  destination_cidr_block = data.aws_subnet.subnet_privatelearningv2.cidr_block
  routetable_id          = data.aws_route_table.vpc_a-rt_private.id
}