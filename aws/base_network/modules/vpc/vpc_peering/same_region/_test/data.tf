/**
 * Data Sources for Test Module
 *
 * Looks up subnets for test EC2 instances.
 * Uses exact Name tags from base_network for precise matching.
 *
 * Note: AMI IDs are loaded from amis.yaml config file via locals.tf
 */

/** Get public subnet in vpc_a by exact Name tag (for bastion) */
data "aws_subnet" "vpc_a_public" {
  filter {
    name   = "tag:Name"
    values = [local.vpc_a_public_subnet_name]
  }
}

/** Get private subnet in vpc_a by exact Name tag (for target instance) */
data "aws_subnet" "vpc_a_private" {
  filter {
    name   = "tag:Name"
    values = [local.vpc_a_private_subnet_name]
  }
}

/** Get private subnet in vpc_b by exact Name tag (for target instance) */
data "aws_subnet" "vpc_b_private" {
  filter {
    name   = "tag:Name"
    values = [local.vpc_b_private_subnet_name]
  }
}
