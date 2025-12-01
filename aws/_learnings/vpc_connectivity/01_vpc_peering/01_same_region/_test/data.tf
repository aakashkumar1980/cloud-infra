/**
 * Data Sources for Test Module
 *
 * Looks up subnets and AMI for test EC2 instances.
 * Uses exact Name tags from base_network for precise matching.
 */

/** Get latest Amazon Linux 2023 AMI */
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

/** Get public subnet in vpc_a by exact Name tag */
data "aws_subnet" "vpc_a_public" {
  filter {
    name   = "tag:Name"
    values = [local.vpc_a_public_subnet_name]
  }
}

/** Get private subnet in vpc_b by exact Name tag */
data "aws_subnet" "vpc_b_private" {
  filter {
    name   = "tag:Name"
    values = [local.vpc_b_private_subnet_name]
  }
}
