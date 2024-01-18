data "aws_vpc" "vpc_a" {
  provider = aws.rnvg

  filter {
    name   = "tag:Name"
    values = ["${var.ns}.vpc_a"]
  }
}

data "aws_vpc" "vpc_c" {
  provider = aws.rldn

  filter {
    name   = "tag:Name"
    values = ["${var.ns}.vpc_c"]
  }
}
data "aws_region" "vpc_c-region" {
  provider = aws.rldn
}
