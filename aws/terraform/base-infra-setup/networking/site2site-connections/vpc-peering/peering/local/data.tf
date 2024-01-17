data "aws_vpc" "vpc_a" {
  filter {
    name   = "tag:Name"
    values = ["${var.ns}.vpc_a"]
  }
}

data "aws_vpc" "vpc_b" {
  filter {
    name   = "tag:Name"
    values = ["${var.ns}.vpc_b"]
  }
}
