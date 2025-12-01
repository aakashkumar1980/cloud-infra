/**
 * Data Sources
 *
 * Looks up existing VPCs and route tables created by base_network.
 * This allows us to create peering without modifying the base infrastructure.
 */

/** Look up vpc_a by its Name tag */
data "aws_vpc" "vpc_a" {
  filter {
    name   = "tag:Name"
    values = [local.vpc_a_name]
  }
}

/** Look up vpc_b by its Name tag */
data "aws_vpc" "vpc_b" {
  filter {
    name   = "tag:Name"
    values = [local.vpc_b_name]
  }
}

/** Get all route tables in vpc_a */
data "aws_route_tables" "vpc_a" {
  vpc_id = data.aws_vpc.vpc_a.id
}

/** Get all route tables in vpc_b */
data "aws_route_tables" "vpc_b" {
  vpc_id = data.aws_vpc.vpc_b.id
}
