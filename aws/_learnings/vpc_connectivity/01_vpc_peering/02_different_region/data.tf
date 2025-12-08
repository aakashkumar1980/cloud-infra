/**
 * Data Sources
 *
 * Looks up existing VPCs and route tables created by base_network in both regions.
 * This allows us to create peering without modifying the base infrastructure.
 *
 * N. Virginia (us-east-1): vpc_a - Requester
 * London (eu-west-2):      vpc_c - Accepter
 */

/** Look up vpc_a in N. Virginia by its Name tag */
data "aws_vpc" "vpc_a" {
  provider = aws.nvirginia

  filter {
    name   = "tag:Name"
    values = [local.vpc_a_name]
  }
}

/** Look up vpc_c in London by its Name tag */
data "aws_vpc" "vpc_c" {
  provider = aws.london

  filter {
    name   = "tag:Name"
    values = [local.vpc_c_name]
  }
}

/** Get subnets in vpc_a (N. Virginia) by Name tag */
data "aws_subnet" "vpc_a" {
  provider = aws.nvirginia
  for_each = local.vpc_a_subnets

  filter {
    name   = "tag:Name"
    values = [each.value.name]
  }
}

/** Get subnets in vpc_c (London) by Name tag */
data "aws_subnet" "vpc_c" {
  provider = aws.london
  for_each = local.vpc_c_subnets

  filter {
    name   = "tag:Name"
    values = [each.value.name]
  }
}

/** Get route tables in vpc_a (N. Virginia) by Name tag */
data "aws_route_table" "vpc_a" {
  provider = aws.nvirginia
  for_each = local.vpc_a_subnets

  filter {
    name   = "tag:Name"
    values = [each.value.rt_name]
  }
}

/** Get route tables in vpc_c (London) by Name tag */
data "aws_route_table" "vpc_c" {
  provider = aws.london
  for_each = local.vpc_c_subnets

  filter {
    name   = "tag:Name"
    values = [each.value.rt_name]
  }
}
