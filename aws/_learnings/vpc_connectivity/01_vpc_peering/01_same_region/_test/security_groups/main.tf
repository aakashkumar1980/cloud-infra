/**
 * Security Groups Module
 *
 * Creates security groups for test instances in vpc_a and vpc_b.
 *
 * Architecture:
 *   Bastion (vpc_a public):
 *     - SSH from your IP (for access)
 *     - ICMP from both VPCs (for ping responses)
 *     - All outbound
 *
 *   VPC A Private Instance:
 *     - ICMP from vpc_a (from bastion)
 *     - ICMP from vpc_b (for cross-VPC testing)
 *     - All outbound
 *
 *   VPC B Private Instance:
 *     - ICMP from vpc_a (from bastion via peering)
 *     - All outbound
 */

/**
 * Security Group for Bastion Instance (vpc_a public subnet)
 *
 * Jump host for SSH access and connectivity testing.
 */
resource "aws_security_group" "sg_bastion" {
  name        = "sg-test-bastion-${var.name_suffix}"
  description = "Security group for bastion/jump host in vpc_a public subnet"
  vpc_id      = var.vpc_a_id

  # SSH from your IP
  ingress {
    description = "SSH from allowed IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # ICMP from vpc_a (for internal ping responses)
  ingress {
    description = "ICMP from vpc_a"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_a_cidr]
  }

  # ICMP from vpc_b (for cross-VPC ping responses)
  ingress {
    description = "ICMP from vpc_b"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_b_cidr]
  }

  # All outbound
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-test-bastion-${var.name_suffix}"
  }
}

/**
 * Security Group for VPC A Private Instance
 *
 * Target instance in vpc_a private subnet.
 */
resource "aws_security_group" "sg_vpc_a_private" {
  name        = "sg-test-vpc-a-private-${var.name_suffix}"
  description = "Security group for test instance in vpc_a private subnet"
  vpc_id      = var.vpc_a_id

  # ICMP from vpc_a (from bastion)
  ingress {
    description = "ICMP from vpc_a"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_a_cidr]
  }

  # ICMP from vpc_b (for cross-VPC testing)
  ingress {
    description = "ICMP from vpc_b"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_b_cidr]
  }

  # All outbound
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-test-vpc-a-private-${var.name_suffix}"
  }
}

/**
 * Security Group for VPC B Private Instance
 *
 * Target instance in vpc_b private subnet (cross-VPC target).
 */
resource "aws_security_group" "sg_vpc_b_private" {
  name        = "sg-test-vpc-b-private-${var.name_suffix}"
  description = "Security group for test instance in vpc_b private subnet"
  vpc_id      = var.vpc_b_id

  # ICMP from vpc_a (from bastion via peering)
  ingress {
    description = "ICMP from vpc_a via peering"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_a_cidr]
  }

  # All outbound
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-test-vpc-b-private-${var.name_suffix}"
  }
}
