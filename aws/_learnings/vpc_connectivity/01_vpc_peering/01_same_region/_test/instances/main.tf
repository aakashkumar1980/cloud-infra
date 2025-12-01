/**
 * Instances Module
 *
 * Creates EC2 instances for VPC peering connectivity test.
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
 */

/**
 * Test Instance A - Jump Host in vpc_a
 *
 * This instance is in a public subnet with a public IP.
 * We SSH into this instance to test connectivity to vpc_b.
 */
resource "aws_instance" "instance_a" {
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  subnet_id                   = var.instance_a_subnet_id
  vpc_security_group_ids      = [var.instance_a_sg_id]
  associate_public_ip_address = true
  key_name                    = var.key_name != "" ? var.key_name : null

  user_data = <<-EOF
    #!/bin/bash
    echo "Test Instance A - VPC Peering Connectivity Test" > /etc/motd
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
resource "aws_instance" "instance_b" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  subnet_id              = var.instance_b_subnet_id
  vpc_security_group_ids = [var.instance_b_sg_id]

  tags = {
    Name = "test-instance-b-${var.name_suffix}"
    Role = "target"
  }
}
