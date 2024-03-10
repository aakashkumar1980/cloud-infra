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
data "aws_security_group" "vpc_b-sg_private" {
  provider = aws.rg
  vpc_id   = data.aws_vpc.vpc_b.id

  filter {
    name   = "tag:Name"
    values = ["${data.aws_vpc.vpc_b.tags["Name"]}.sg_private"]
  }
}
data "aws_network_acls" "vpc_b-nacl_private" {
  provider = aws.rg
  vpc_id   = data.aws_vpc.vpc_b.id

  filter {
    name   = "tag:Name"
    values = ["${data.aws_vpc.vpc_b.tags["Name"]}.nacl_private"]
  }
}
data "aws_route_table" "vpc_b-rt_private" {
  provider = aws.rg
  vpc_id   = data.aws_vpc.vpc_b.id

  filter {
    name   = "tag:Name"
    values = ["${data.aws_vpc.vpc_b.tags["Name"]}.rt_private"]
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
