resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    "Name" = "${var.ns}.${var.vpc_name}"
  }
}
