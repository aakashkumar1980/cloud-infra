/** VPC_A **/
data "aws_vpc" "vpc_a" {
  provider = aws.rg
  filter {
    name   = "tag:Name"
    values = ["${var.ns}.vpc_a"]
  }
}
/** VPC_B **/
data "aws_vpc" "vpc_b" {
  provider = aws.rg
  filter {
    name   = "tag:Name"
    values = ["${var.ns}.vpc_b"]
  }
}

/** VPC_C **/
data "aws_vpc" "vpc_c" {
  provider = aws.rn
  filter {
    name   = "tag:Name"
    values = ["${var.ns}.vpc_c"]
  }
}
data "aws_security_group" "vpc_c-sg_private" {
  provider = aws.rn
  vpc_id   = data.aws_vpc.vpc_c.id

  filter {
    name   = "tag:Name"
    values = ["${data.aws_vpc.vpc_c.tags["Name"]}.sg_private"]
  }
}
data "aws_network_acls" "vpc_c-nacl_private" {
  provider = aws.rn
  vpc_id   = data.aws_vpc.vpc_c.id

  filter {
    name   = "tag:Name"
    values = ["${data.aws_vpc.vpc_c.tags["Name"]}.nacl_private"]
  }
}
data "aws_route_table" "vpc_c-rt_private" {
  provider = aws.rn
  vpc_id   = data.aws_vpc.vpc_c.id

  filter {
    name   = "tag:Name"
    values = ["${data.aws_vpc.vpc_c.tags["Name"]}.rt_private"]
  }
}
