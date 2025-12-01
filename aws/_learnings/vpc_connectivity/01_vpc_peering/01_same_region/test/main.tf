/**
 * Connectivity Test Module
 *
 * Creates EC2 instances in vpc_a and vpc_b to validate VPC peering connectivity.
 *
 * Test Architecture:
 *
 *   ┌─────────────────────────────────────────────────────────────────┐
 *   │                        Internet                                 │
 *   └──────────────────────────┬──────────────────────────────────────┘
 *                              │
 *                              │ SSH (port 22)
 *                              ▼
 *   ┌────────────────────────────────┐    ┌────────────────────────────┐
 *   │           VPC A                │    │           VPC B            │
 *   │       (10.0.0.0/24)            │    │      (172.16.0.0/26)       │
 *   │                                │    │                            │
 *   │  ┌──────────────────────────┐  │    │  ┌──────────────────────┐  │
 *   │  │    Public Subnet         │  │    │  │   Private Subnet     │  │
 *   │  │                          │  │    │  │                      │  │
 *   │  │  ┌────────────────────┐  │  │    │  │  ┌────────────────┐  │  │
 *   │  │  │   Test Instance A  │──┼──┼────┼──┼──│ Test Instance B│  │  │
 *   │  │  │   (Jump Host)      │  │  │    │  │  │   (Target)     │  │  │
 *   │  │  │                    │  │  │    │  │  │                │  │  │
 *   │  │  │   Public IP: Yes   │  │  │    │  │  │ Public IP: No  │  │  │
 *   │  │  └────────────────────┘  │  │    │  │  └────────────────┘  │  │
 *   │  │                          │  │    │  │                      │  │
 *   │  └──────────────────────────┘  │    │  └──────────────────────┘  │
 *   │                                │    │                            │
 *   └────────────────────────────────┘    └────────────────────────────┘
 *                              │                        │
 *                              └────────────────────────┘
 *                                  VPC Peering (ICMP)
 *
 * Test Steps:
 *   1. SSH into Test Instance A (vpc_a, public subnet)
 *   2. Ping Test Instance B (vpc_b, private subnet) using private IP
 *   3. If ping succeeds, VPC peering is working correctly
 */

/**
 * Security Group for Test Instance A (vpc_a)
 *
 * Allows:
 *   - SSH from your IP (for management)
 *   - ICMP from vpc_b (for ping responses)
 *   - All outbound traffic
 */
resource "aws_security_group" "test_instance_a" {
  name        = "test-instance-a-sg-${var.name_suffix}"
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
    Name = "test-instance-a-sg-${var.name_suffix}"
  }
}

/**
 * Security Group for Test Instance B (vpc_b)
 *
 * Allows:
 *   - ICMP from vpc_a (for ping)
 *   - All outbound traffic
 */
resource "aws_security_group" "test_instance_b" {
  name        = "test-instance-b-sg-${var.name_suffix}"
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
    Name = "test-instance-b-sg-${var.name_suffix}"
  }
}

/**
 * Test Instance A - Jump Host in vpc_a
 *
 * This instance is in a public subnet with a public IP.
 * We SSH into this instance to test connectivity to vpc_b.
 */
resource "aws_instance" "test_a" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnet.vpc_a_public.id
  vpc_security_group_ids      = [aws_security_group.test_instance_a.id]
  associate_public_ip_address = true
  key_name                    = var.key_name != "" ? var.key_name : null

  user_data = <<-EOF
    #!/bin/bash
    echo "Test Instance A - VPC Peering Connectivity Test" > /etc/motd
    echo "Target IP (Instance B): Will be available after deployment" >> /etc/motd
  EOF

  tags = {
    Name = "test-instance-a-${var.name_suffix}"
    Role = "jump-host"
  }
}

/**
 * Test Instance B - Target in vpc_b
 *
 * This instance is in a private subnet without a public IP.
 * It's the target for our connectivity test from Instance A.
 */
resource "aws_instance" "test_b" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnet.vpc_b_private.id
  vpc_security_group_ids = [aws_security_group.test_instance_b.id]

  tags = {
    Name = "test-instance-b-${var.name_suffix}"
    Role = "target"
  }
}
