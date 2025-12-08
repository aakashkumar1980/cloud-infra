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
 * Instances (creation order):
 *   1. vpc_a_private_ec2               - Target in same VPC (validates internal routing)
 *   2. vpc_b_private_ec2               - Target in peered VPC (validates peering)
 *   3. bastion_ec2 (vpc_a public)      - Jump host (created last to get private IPs)
 */

/**
 * VPC A Private EC2 Instance - Test source in vpc_a private subnet
 *
 * This instance runs the connectivity test to VPC B private EC2.
 * No public IP (private subnet).
 * Access via bastion (jump host).
 */
resource "aws_instance" "vpc_a_private_ec2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.vpc_a_private_subnet_id
  vpc_security_group_ids = [var.vpc_a_private_sg_id]
  key_name               = var.key_name != "" ? var.key_name : null

  # VPC A Private depends on VPC B Private to get its IP for the test script
  depends_on = [
    aws_instance.vpc_b_private_ec2
  ]

  user_data = <<-EOF
    #!/bin/bash
    echo "=== VPC Peering Connectivity Test - Source Instance ===" > /etc/motd

    # Install iperf3 for bandwidth testing
    yum install -y iperf3

    # Create connectivity test script with pre-configured IP
    cat > /home/ec2-user/test_connectivity.sh << 'SCRIPT'
    ${templatefile("${path.module}/test_connectivity.sh", {
      vpc_a_private_ip = ""
      vpc_b_private_ip = aws_instance.vpc_b_private_ec2.private_ip
    })}
    SCRIPT

    chmod +x /home/ec2-user/test_connectivity.sh
    chown ec2-user:ec2-user /home/ec2-user/test_connectivity.sh

    # Create a simple readme
    cat > /home/ec2-user/README.txt << 'README'
    VPC Peering Connectivity Test
    =============================

    Target IP (pre-configured):
      - VPC B Private: ${aws_instance.vpc_b_private_ec2.private_ip}

    Commands:
      ./test_connectivity.sh          # Run ping + bandwidth tests
      ./test_connectivity.sh ping     # Run ping test only
      ./test_connectivity.sh speed    # Run bandwidth test only

    Manual iperf3 commands:
      iperf3 -c ${aws_instance.vpc_b_private_ec2.private_ip}   # Test to VPC B

    README
    chown ec2-user:ec2-user /home/ec2-user/README.txt
  EOF

  tags = {
    Name = "test_vpc-a-private-ec2-${var.name_suffix}"
    Role = "test-source"
  }
}

/**
 * VPC B Private EC2 Instance - Target in vpc_b private subnet
 *
 * This instance validates cross-VPC connectivity via peering.
 * No public IP (private subnet in different VPC).
 * Runs iperf3 server for bandwidth testing.
 */
resource "aws_instance" "vpc_b_private_ec2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.vpc_b_private_subnet_id
  vpc_security_group_ids = [var.vpc_b_private_sg_id]
  key_name               = var.key_name != "" ? var.key_name : null

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
    Name = "test_vpc-b-private-ec2-${var.name_suffix}"
    Role = "target-cross-vpc"
  }
}

/**
 * Bastion EC2 Instance - Jump Host in vpc_a public subnet
 *
 * This instance has a public IP for SSH access.
 * Used only as a jump host to SSH into VPC A private EC2.
 */
resource "aws_instance" "bastion_ec2" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.bastion_subnet_id
  vpc_security_group_ids      = [var.bastion_sg_id]
  associate_public_ip_address = true
  key_name                    = var.key_name != "" ? var.key_name : null

  # Bastion depends on private instance to get its IP
  depends_on = [
    aws_instance.vpc_a_private_ec2
  ]

  user_data = <<-EOF
    #!/bin/bash
    echo "=== VPC Peering - Jump Host ===" > /etc/motd

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
    VPC Peering Connectivity Test - Jump Host
    =========================================

    This is a jump host. SSH into VPC A Private to run the connectivity test.

    SSH to VPC A Private:
      ssh ec2-user@${aws_instance.vpc_a_private_ec2.private_ip}

    Then run the test:
      ./test_connectivity.sh

    README
    chown ec2-user:ec2-user /home/ec2-user/README.txt
  EOF

  tags = {
    Name = "test_bastion-vpc-a-public-ec2-${var.name_suffix}"
    Role = "bastion"
  }
}
