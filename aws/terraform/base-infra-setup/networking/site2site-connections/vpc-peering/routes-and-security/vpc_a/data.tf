data "aws_vpc" "vpc_a" {
  provider = aws.rn
  filter {
    name   = "tag:Name"
    values = ["${var.ns}.vpc_a"]
  }
}
data "aws_security_group" "vpc_a-sg_private" {
  provider = aws.rn
  vpc_id   = data.aws_vpc.vpc_a.id

  filter {
    name   = "tag:Name"
    values = ["${data.aws_vpc.vpc_a.tags["Name"]}.sg_private"]
  }
}
data "aws_network_acls" "vpc_a-nacl_private" {
  provider = aws.rn
  vpc_id   = data.aws_vpc.vpc_a.id

  filter {
    name   = "tag:Name"
    values = ["${data.aws_vpc.vpc_a.tags["Name"]}.nacl_private"]
  }
}
data "aws_route_table" "vpc_a-rt_private" {
  provider = aws.rn
  vpc_id   = data.aws_vpc.vpc_a.id

  filter {
    name   = "tag:Name"
    values = ["${data.aws_vpc.vpc_a.tags["Name"]}.rt_private"]
  }
}


data "aws_vpc" "vpc_b" {
  provider = aws.rn
  filter {
    name   = "tag:Name"
    values = ["${var.ns}.vpc_b"]
  }
}


data "aws_vpc" "vpc_c" {
  provider = aws.rl
  filter {
    name   = "tag:Name"
    values = ["${var.ns}.vpc_c"]
  }
}