/**
 * Instances Module - Cross-Region
 *
 * Creates EC2 instances for cross-region VPC peering connectivity test.
 *
 * Test Architecture:
 *
 *   ┌─────────────────────────────────────────────────────────────────────────┐
 *   │                             Internet                                    │
 *   └───────────────────────────────┬─────────────────────────────────────────┘
 *                                   │
 *                                   │ SSH (port 22)
 *                                   ▼
 *   ┌─────────────────────────────────────────────┐    ┌─────────────────────────────┐
 *   │        N. Virginia (us-east-1)              │    │      London (eu-west-2)     │
 *   │           VPC A (10.0.0.0/24)               │    │   VPC C (192.168.0.0/26)    │
 *   │                                             │    │                             │
 *   │  ┌───────────────────────────────────────┐  │    │                             │
 *   │  │           Public Subnet               │  │    │                             │
 *   │  │  ┌─────────────────────────────────┐  │  │    │                             │
 *   │  │  │   Bastion (Jump Host)           │  │  │    │                             │
 *   │  │  │   Public IP: Yes                │  │  │    │                             │
 *   │  │  └──────────────┬──────────────────┘  │  │    │                             │
 *   │  └─────────────────┼─────────────────────┘  │    │                             │
 *   │                    │                        │    │                             │
 *   │  ┌─────────────────┼─────────────────────┐  │    │  ┌───────────────────────┐  │
 *   │  │           Private Subnet              │  │    │  │    Private Subnet     │  │
 *   │  │                 │                     │  │    │  │                       │  │
 *   │  │  ┌──────────────▼───────────────────┐ │  │    │  │  ┌─────────────────┐  │  │
 *   │  │  │   VPC A Private Instance         │─┼──┼────┼──┼──│VPC C Instance   │  │  │
 *   │  │  │   (Same VPC Target)              │ │  │    │  │  │(Cross-Region)   │  │  │
 *   │  │  └──────────────────────────────────┘ │  │    │  │  └─────────────────┘  │  │
 *   │  │                                       │  │    │  │                       │  │
 *   │  └───────────────────────────────────────┘  │    │  └───────────────────────┘  │
 *   │                                             │    │                             │
 *   └─────────────────────────────────────────────┘    └─────────────────────────────┘
 *                                   │                              │
 *                                   └──────────────────────────────┘
 *                                      Cross-Region VPC Peering
 *                                         (~60-100ms latency)
 *
 * Instances (creation order):
 *   1. vpc_a_private_ec2 (N. Virginia) - Target in same VPC
 *   2. vpc_c_private_ec2 (London)      - Target in peered VPC (cross-region)
 *   3. bastion_ec2 (N. Virginia)       - Jump host (created last to get private IPs)
 */

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.nvirginia, aws.london]
    }
  }
}

/**
 * VPC A Private EC2 Instance - Test source in vpc_a private subnet (N. Virginia)
 *
 * This instance runs the connectivity test to VPC C private EC2 (cross-region).
 * No public IP (private subnet).
 * Access via bastion (jump host).
 */
resource "aws_instance" "vpc_a_private_ec2" {
  provider = aws.nvirginia

  ami                    = var.ami_id_nvirginia
  instance_type          = var.instance_type
  subnet_id              = var.vpc_a_private_subnet_id
  vpc_security_group_ids = [var.vpc_a_private_sg_id]
  key_name               = var.key_name_nvirginia != "" ? var.key_name_nvirginia : null

  # VPC A Private depends on VPC C Private to get its IP for the test script
  depends_on = [
    aws_instance.vpc_c_private_ec2
  ]

  user_data = <<-EOF
    #!/bin/bash
    echo "=== Cross-Region VPC Peering Test - Source Instance ===" > /etc/motd

    # Install iperf3 for bandwidth testing
    yum install -y iperf3

    # Create connectivity test script with pre-configured IP
    cat > /home/ec2-user/test_connectivity.sh << 'SCRIPT'
    ${templatefile("${path.module}/test_connectivity.sh", {
      vpc_c_private_ip = aws_instance.vpc_c_private_ec2.private_ip
    })}
    SCRIPT

    chmod +x /home/ec2-user/test_connectivity.sh
    chown ec2-user:ec2-user /home/ec2-user/test_connectivity.sh

    # Create a simple readme
    cat > /home/ec2-user/README.txt << 'README'
    Cross-Region VPC Peering Connectivity Test
    ==========================================

    Target IP (pre-configured):
      - VPC C Private (London): ${aws_instance.vpc_c_private_ec2.private_ip}

    Commands:
      ./test_connectivity.sh          # Run ping + bandwidth tests
      ./test_connectivity.sh ping     # Run ping test only
      ./test_connectivity.sh speed    # Run bandwidth test only

    Manual iperf3 commands:
      iperf3 -c ${aws_instance.vpc_c_private_ec2.private_ip}   # Test to VPC C (cross-region)

    Expected Latency:
      - Cross-region (London): ~60-100ms

    README
    chown ec2-user:ec2-user /home/ec2-user/README.txt
  EOF

  tags = {
    Name   = "test_vpc_a-private-ec2-${var.name_suffix_nvirginia}"
    Role   = "test-source"
    Region = "us-east-1"
  }
}

/**
 * VPC C Private EC2 Instance - Target in vpc_c private subnet (London)
 *
 * This instance validates cross-region connectivity via peering.
 * No public IP (private subnet in different region).
 * Runs iperf3 server for bandwidth testing.
 */
resource "aws_instance" "vpc_c_private_ec2" {
  provider = aws.london

  ami                    = var.ami_id_london
  instance_type          = var.instance_type
  subnet_id              = var.vpc_c_private_subnet_id
  vpc_security_group_ids = [var.vpc_c_private_sg_id]
  key_name               = var.key_name_london != "" ? var.key_name_london : null

  user_data = <<-EOF
    #!/bin/bash
    # Install iperf3 for bandwidth testing
    yum install -y iperf3

    # Start iperf3 server (runs on port 5201)
    # Run as a systemd service for persistence
    cat > /etc/systemd/system/iperf3.service << 'SERVICE'
    [Unit]
    Description=iperf3 server
    After=network.target

    [Service]
    Type=simple
    ExecStart=/usr/bin/iperf3 -s
    Restart=always

    [Install]
    WantedBy=multi-user.target
    SERVICE

    systemctl daemon-reload
    systemctl enable iperf3
    systemctl start iperf3
  EOF

  tags = {
    Name   = "test_vpc_c-private-ec2-${var.name_suffix_london}"
    Role   = "target-cross-region"
    Region = "eu-west-2"
  }
}

/**
 * Bastion EC2 Instance - Jump Host in vpc_a public subnet (N. Virginia)
 *
 * This instance has a public IP for SSH access.
 * Used only as a jump host to SSH into VPC A private EC2.
 */
resource "aws_instance" "bastion_ec2" {
  provider = aws.nvirginia

  ami                         = var.ami_id_nvirginia
  instance_type               = var.instance_type
  subnet_id                   = var.bastion_subnet_id
  vpc_security_group_ids      = [var.bastion_sg_id]
  associate_public_ip_address = true
  key_name                    = var.key_name_nvirginia != "" ? var.key_name_nvirginia : null

  # Bastion depends on private instance to get its IP
  depends_on = [
    aws_instance.vpc_a_private_ec2
  ]

  user_data = <<-EOF
    #!/bin/bash
    echo "=== Cross-Region VPC Peering - Jump Host ===" > /etc/motd

    # Copy private key for SSH access to private instances
    %{ if var.private_key_pem != "" }
    cat > /home/ec2-user/.ssh/id_rsa << 'PRIVATEKEY'
    ${var.private_key_pem}
    PRIVATEKEY
    chmod 600 /home/ec2-user/.ssh/id_rsa
    chown ec2-user:ec2-user /home/ec2-user/.ssh/id_rsa
    %{ endif }

    # Create a simple readme
    cat > /home/ec2-user/README.txt << 'README'
    Cross-Region VPC Peering Connectivity Test - Jump Host
    ======================================================

    This is a jump host. SSH into VPC A Private to run the connectivity test.

    SSH to VPC A Private:
      ssh ec2-user@${aws_instance.vpc_a_private_ec2.private_ip}

    Then run the test:
      ./test_connectivity.sh

    README
    chown ec2-user:ec2-user /home/ec2-user/README.txt
  EOF

  tags = {
    Name   = "test_bastion-vpc_a-public-ec2-${var.name_suffix_nvirginia}"
    Role   = "bastion"
    Region = "us-east-1"
  }
}
