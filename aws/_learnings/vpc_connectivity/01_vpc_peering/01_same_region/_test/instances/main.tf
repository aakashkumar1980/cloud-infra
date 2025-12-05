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
 *   ┌────────────────────────────────────────┐    ┌──────────────────────────┐
 *   │              VPC A (10.0.0.0/24)       │    │  VPC B (172.16.0.0/26)   │
 *   │                                        │    │                          │
 *   │  ┌──────────────────────────────────┐  │    │                          │
 *   │  │         Public Subnet            │  │    │                          │
 *   │  │  ┌────────────────────────────┐  │  │    │                          │
 *   │  │  │   Bastion (Jump Host)      │  │  │    │                          │
 *   │  │  │   Public IP: Yes           │  │  │    │                          │
 *   │  │  └─────────────┬──────────────┘  │  │    │                          │
 *   │  └────────────────┼─────────────────┘  │    │                          │
 *   │                   │                    │    │                          │
 *   │  ┌────────────────┼─────────────────┐  │    │  ┌────────────────────┐  │
 *   │  │         Private Subnet           │  │    │  │   Private Subnet   │  │
 *   │  │                │                 │  │    │  │                    │  │
 *   │  │  ┌─────────────▼──────────────┐  │  │    │  │  ┌──────────────┐  │  │
 *   │  │  │   VPC A Private Instance   │──┼──┼────┼──┼──│VPC B Instance│  │  │
 *   │  │  │   (Same VPC Target)        │  │  │    │  │  │(Cross-VPC)   │  │  │
 *   │  │  └────────────────────────────┘  │  │    │  │  └──────────────┘  │  │
 *   │  │                                  │  │    │  │                    │  │
 *   │  └──────────────────────────────────┘  │    │  └────────────────────┘  │
 *   │                                        │    │                          │
 *   └────────────────────────────────────────┘    └──────────────────────────┘
 *                              │                              │
 *                              └──────────────────────────────┘
 *                                     VPC Peering (ICMP)
 *
 * Instances:
 *   1. bastion_ec2 (vpc_a public)      - Jump host with public IP for SSH access
 *   2. vpc_a_private_ec2               - Target in same VPC (validates internal routing)
 *   3. vpc_b_private_ec2               - Target in peered VPC (validates peering)
 */

/**
 * Bastion EC2 Instance - Jump Host in vpc_a public subnet
 *
 * This instance has a public IP for SSH access.
 * It includes a connectivity test script loaded from external file.
 */
resource "aws_instance" "bastion_ec2" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.bastion_subnet_id
  vpc_security_group_ids      = [var.bastion_sg_id]
  associate_public_ip_address = true
  key_name                    = var.key_name != "" ? var.key_name : null

  user_data = <<-EOF
    #!/bin/bash
    echo "=== VPC Peering Connectivity Test Bastion ===" > /etc/motd

    # Create connectivity test script from external file
    cat > /home/ec2-user/test_connectivity.sh << 'SCRIPT'
    ${file("${path.module}/test_connectivity.sh")}
    SCRIPT

    chmod +x /home/ec2-user/test_connectivity.sh
    chown ec2-user:ec2-user /home/ec2-user/test_connectivity.sh
  EOF

  tags = {
    Name = "test-bastion-ec2-${var.name_suffix}"
    Role = "bastion"
  }
}

/**
 * VPC A Private EC2 Instance - Target in vpc_a private subnet
 *
 * This instance validates internal VPC routing.
 * No public IP (private subnet).
 */
resource "aws_instance" "vpc_a_private_ec2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.vpc_a_private_subnet_id
  vpc_security_group_ids = [var.vpc_a_private_sg_id]

  tags = {
    Name = "test-vpc-a-private-ec2-${var.name_suffix}"
    Role = "target-same-vpc"
  }
}

/**
 * VPC B Private EC2 Instance - Target in vpc_b private subnet
 *
 * This instance validates cross-VPC connectivity via peering.
 * No public IP (private subnet in different VPC).
 */
resource "aws_instance" "vpc_b_private_ec2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.vpc_b_private_subnet_id
  vpc_security_group_ids = [var.vpc_b_private_sg_id]

  tags = {
    Name = "test-vpc-b-private-ec2-${var.name_suffix}"
    Role = "target-cross-vpc"
  }
}
