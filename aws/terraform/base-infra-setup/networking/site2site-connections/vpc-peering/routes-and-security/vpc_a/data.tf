data "aws_vpc" "vpc_a" {
  filter {
    name   = "tag:Name"
    values = ["${var.ns}.vpc_a"]
  }
}
data "aws_security_group" "vpc_a_sg_private" {
  vpc_id = data.aws_vpc.vpc_a.id

  filter {
    name   = "tag:Name"
    values = ["${data.aws_vpc.vpc_a.tags["Name"]}.sg_private"]
  }
}

data "aws_vpc" "vpc_b" {
  filter {
    name   = "tag:Name"
    values = ["${var.ns}.vpc_b"]
  }
}
