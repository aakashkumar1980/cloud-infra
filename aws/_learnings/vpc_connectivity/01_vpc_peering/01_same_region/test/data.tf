/**
 * Data Sources for Test Module
 *
 * Looks up subnets and AMI for test EC2 instances.
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

/** Get public subnet in vpc_a */
data "aws_subnet" "vpc_a_public" {
  vpc_id = var.vpc_a_id

  filter {
    name   = "tag:Name"
    values = ["*public*"]
  }
}

/** Get private subnet in vpc_b */
data "aws_subnet" "vpc_b_private" {
  vpc_id = var.vpc_b_id

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}
