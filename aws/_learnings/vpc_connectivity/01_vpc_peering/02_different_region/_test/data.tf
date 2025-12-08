/**
 * Data Sources for Test Module - Cross-Region
 *
 * Looks up subnets for test EC2 instances in both regions.
 * Uses exact Name tags from base_network for precise matching.
 *
 * Note: AMI IDs are loaded from amis.yaml config file via locals.tf
 */

/** Get public subnet in vpc_a (N. Virginia) by exact Name tag (for bastion) */
data "aws_subnet" "vpc_a_public" {
  provider = aws.nvirginia

  filter {
    name   = "tag:Name"
    values = [local.vpc_a_public_subnet_name]
  }
}

/** Get private subnet in vpc_a (N. Virginia) by exact Name tag (for target instance) */
data "aws_subnet" "vpc_a_private" {
  provider = aws.nvirginia

  filter {
    name   = "tag:Name"
    values = [local.vpc_a_private_subnet_name]
  }
}

/** Get private subnet in vpc_c (London) by exact Name tag (for target instance) */
data "aws_subnet" "vpc_c_private" {
  provider = aws.london

  filter {
    name   = "tag:Name"
    values = [local.vpc_c_private_subnet_name]
  }
}
