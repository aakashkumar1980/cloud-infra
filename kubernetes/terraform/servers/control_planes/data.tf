data "aws_vpc" "vpc_c" {
  provider = aws.rgn_ldn
  filter {
    name   = "tag:Name"
    values = ["${var.base_ns}.vpc_c"]
  }
}
data "aws_subnet" "subnet_private" {
  provider = aws.rgn_ldn
  vpc_id   = data.aws_vpc.vpc_c.id

  filter {
    name   = "tag:Name"
    values = ["*.subnet_private-*"]
  }
}
data "aws_security_group" "sg_private" {
  provider = aws.rgn_ldn
  vpc_id   = data.aws_vpc.vpc_c.id

  filter {
    name   = "tag:Name"
    values = ["*.sg_private*"]
  }
}

