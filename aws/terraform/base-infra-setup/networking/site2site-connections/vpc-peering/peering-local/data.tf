data "aws_vpc" "vpc_a" {
  filter {
    name   = "tag:Name"
    values = [local.local_peering.vpc_a.vpc_tagname]
  }
}

data "aws_vpc" "vpc_b" {
  filter {
    name   = "tag:Name"
    values = [local.local_peering.vpc_b.vpc_tagname]
  }
}
