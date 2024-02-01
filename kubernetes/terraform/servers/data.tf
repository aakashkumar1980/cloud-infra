data "aws_vpc" "vpc_a" {
  provider = aws.region_nvirginia
  filter {
    name   = "tag:Name"
    values = ["${module.COMMON-BASE_INFRA_SETUP.project.namespace}.vpc_a"]
  }
}
data "aws_subnet" "vpc_a-subnet_private" {
  provider = aws.region_nvirginia
  vpc_id   = data.aws_vpc.vpc_a.id

  filter {
    name   = "tag:Name"
    values = ["${module.COMMON-BASE_INFRA_SETUP.project.namespace}.vpc_a.subnet_private-az_c"]
  }
}
data "aws_security_group" "vpc_a-sg_private" {
  provider = aws.region_nvirginia
  vpc_id   = data.aws_vpc.vpc_a.id

  filter {
    name   = "tag:Name"
    values = ["${module.COMMON-BASE_INFRA_SETUP.project.namespace}.vpc_a.sg_private"]
  }
}


data "aws_vpc" "vpc_b" {
  provider = aws.region_nvirginia
  filter {
    name   = "tag:Name"
    values = ["${module.COMMON-BASE_INFRA_SETUP.project.namespace}.vpc_b"]
  }
}
data "aws_subnet" "vpc_b-subnet_private" {
  provider = aws.region_nvirginia
  vpc_id   = data.aws_vpc.vpc_b.id

  filter {
    name   = "tag:Name"
    values = ["${module.COMMON-BASE_INFRA_SETUP.project.namespace}.vpc_b.subnet_private-az_c"]
  }
}
data "aws_security_group" "vpc_b-sg_private" {
  provider = aws.region_nvirginia
  vpc_id   = data.aws_vpc.vpc_b.id

  filter {
    name   = "tag:Name"
    values = ["${module.COMMON-BASE_INFRA_SETUP.project.namespace}.vpc_b.sg_private"]
  }
}


data "aws_vpc" "vpc_c" {
  provider = aws.region_london
  filter {
    name   = "tag:Name"
    values = ["${module.COMMON-BASE_INFRA_SETUP.project.namespace}.vpc_c"]
  }
}
data "aws_subnet" "vpc_c-subnet_private" {
  provider = aws.region_london
  vpc_id   = data.aws_vpc.vpc_c.id

  filter {
    name   = "tag:Name"
    values = ["${module.COMMON-BASE_INFRA_SETUP.project.namespace}.vpc_c.subnet_private-az_c"]
  }
}
data "aws_security_group" "vpc_c-sg_private" {
  provider = aws.region_london
  vpc_id   = data.aws_vpc.vpc_c.id

  filter {
    name   = "tag:Name"
    values = ["${module.COMMON-BASE_INFRA_SETUP.project.namespace}.vpc_c.sg_private"]
  }
}
