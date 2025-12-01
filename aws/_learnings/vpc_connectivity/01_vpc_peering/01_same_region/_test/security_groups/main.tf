/**
 * Security Groups Module
 *
 * Creates security groups for test instances in vpc_a and vpc_b.
 *
 * Instance A (vpc_a, jump host):
 *   - SSH from your IP
 *   - ICMP from vpc_b (for ping responses)
 *   - All outbound
 *
 * Instance B (vpc_b, target):
 *   - ICMP from vpc_a (for ping)
 *   - All outbound
 */

/**
 * Security Group for Test Instance A (vpc_a)
 */
resource "aws_security_group" "sg_instance_a" {
  name        = "sg-test-instance-a-${var.name_suffix}"
  description = "Security group for test instance in vpc_a"
  vpc_id      = var.vpc_a_id

  # SSH from your IP
  ingress {
    description = "SSH from allowed IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # ICMP from vpc_b (for ping responses)
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
    Name = "sg-test-instance-a-${var.name_suffix}"
  }
}

/**
 * Security Group for Test Instance B (vpc_b)
 */
resource "aws_security_group" "sg_instance_b" {
  name        = "sg-test-instance-b-${var.name_suffix}"
  description = "Security group for test instance in vpc_b"
  vpc_id      = var.vpc_b_id

  # ICMP from vpc_a (for ping)
  ingress {
    description = "ICMP from vpc_a"
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
    Name = "sg-test-instance-b-${var.name_suffix}"
  }
}
