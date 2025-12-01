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

/** Get route tables in vpc_a by Name tag */
data "aws_route_table" "vpc_a" {
  for_each = toset(local.vpc_a_route_table_names)

  filter {
    name   = "tag:Name"
    values = [each.value]
  }
}

/** Get route tables in vpc_b by Name tag */
data "aws_route_table" "vpc_b" {
  for_each = toset(local.vpc_b_route_table_names)

  filter {
    name   = "tag:Name"
    values = [each.value]
  }
}
