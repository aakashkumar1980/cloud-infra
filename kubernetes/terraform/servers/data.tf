data "aws_vpc" "vpc_a" {
  provider = aws.region_nvirginia
  filter {
    name   = "tag:Name"
    values = ["${module.COMMON-BASE_INFRA_SETUP.project.namespace}.vpc_a"]
  }
}
data "aws_network_acls" "vpc_a-nacl_private" {
  provider = aws.region_nvirginia
  vpc_id   = data.aws_vpc.vpc_a.id

  filter {
    name   = "tag:Name"
    values = ["${data.aws_vpc.vpc_a.tags["Name"]}.nacl_private"]
  }
}

data "aws_vpc" "vpc_b" {
  provider = aws.region_nvirginia
  filter {
    name   = "tag:Name"
    values = ["${module.COMMON-BASE_INFRA_SETUP.project.namespace}.vpc_b"]
  }
}
data "aws_network_acls" "vpc_b-nacl_private" {
  provider = aws.region_nvirginia
  vpc_id   = data.aws_vpc.vpc_b.id

  filter {
    name   = "tag:Name"
    values = ["${data.aws_vpc.vpc_b.tags["Name"]}.nacl_private"]
  }
}

data "aws_vpc" "vpc_c" {
  provider = aws.region_london
  filter {
    name   = "tag:Name"
    values = ["${module.COMMON-BASE_INFRA_SETUP.project.namespace}.vpc_c"]
  }
}
data "aws_network_acls" "vpc_c-nacl_private" {
  provider = aws.region_london
  vpc_id   = data.aws_vpc.vpc_c.id

  filter {
    name   = "tag:Name"
    values = ["${data.aws_vpc.vpc_c.tags["Name"]}.nacl_private"]
  }
}
