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
 *   1. Bastion (vpc_a public)     - Jump host with public IP for SSH access
 *   2. VPC A Private Instance     - Target in same VPC (validates internal routing)
 *   3. VPC B Private Instance     - Target in peered VPC (validates peering)
 */

/**
 * Bastion Instance - Jump Host in vpc_a public subnet
 *
 * This instance has a public IP for SSH access.
 * It includes a connectivity test script for validating VPC peering.
 */
resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.bastion_subnet_id
  vpc_security_group_ids      = [var.bastion_sg_id]
  associate_public_ip_address = true
  key_name                    = var.key_name != "" ? var.key_name : null

  user_data = <<-EOF
    #!/bin/bash
    echo "=== VPC Peering Connectivity Test Bastion ===" > /etc/motd

    # Create connectivity test script
    cat > /home/ec2-user/test_connectivity.sh << 'SCRIPT'
    #!/bin/bash
    #
    # VPC Peering Connectivity Test Script
    # Tests connectivity from bastion to private instances
    #
    # Usage: ./test_connectivity.sh <vpc_a_private_ip> <vpc_b_private_ip>
    #    or: ./test_connectivity.sh (will prompt for IPs)
    #

    # Colors for output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color

    # Get target IPs from arguments or prompt
    if [ $# -eq 2 ]; then
        VPC_A_PRIVATE_IP="$1"
        VPC_B_PRIVATE_IP="$2"
    else
        echo "╔══════════════════════════════════════════════════════════════════╗"
        echo "║           VPC PEERING CONNECTIVITY TEST                          ║"
        echo "╚══════════════════════════════════════════════════════════════════╝"
        echo ""
        echo "Enter the target IP addresses (from Terraform output):"
        echo ""
        read -p "VPC A Private Instance IP: " VPC_A_PRIVATE_IP
        read -p "VPC B Private Instance IP: " VPC_B_PRIVATE_IP
        echo ""
    fi

    # Validate IPs
    if [ -z "$VPC_A_PRIVATE_IP" ] || [ -z "$VPC_B_PRIVATE_IP" ]; then
        echo -e "${RED}Error: Both IP addresses are required${NC}"
        echo "Usage: ./test_connectivity.sh <vpc_a_private_ip> <vpc_b_private_ip>"
        exit 1
    fi

    test_connectivity() {
        local target_ip=$1
        local target_name=$2

        echo -n "Testing $target_name ($target_ip)... "

        if ping -c 3 -W 2 "$target_ip" > /dev/null 2>&1; then
            echo -e "${GREEN}SUCCESS${NC} - Ping successful"
            return 0
        else
            echo -e "${RED}FAILED${NC} - No response"
            return 1
        fi
    }

    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║           VPC PEERING CONNECTIVITY TEST                          ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""

    echo "┌──────────────────────────────────────────────────────────────────┐"
    echo "│ Test 1: Same VPC Connectivity (Bastion -> VPC A Private)        │"
    echo "└──────────────────────────────────────────────────────────────────┘"
    test_connectivity "$VPC_A_PRIVATE_IP" "VPC A Private Instance"
    TEST1_RESULT=$?
    echo ""

    echo "┌──────────────────────────────────────────────────────────────────┐"
    echo "│ Test 2: Cross-VPC Connectivity (Bastion -> VPC B via Peering)   │"
    echo "└──────────────────────────────────────────────────────────────────┘"
    test_connectivity "$VPC_B_PRIVATE_IP" "VPC B Private Instance"
    TEST2_RESULT=$?
    echo ""

    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                         TEST SUMMARY                             ║"
    echo "╠══════════════════════════════════════════════════════════════════╣"

    if [ $TEST1_RESULT -eq 0 ] && [ $TEST2_RESULT -eq 0 ]; then
        echo -e "║  ${GREEN}ALL TESTS PASSED${NC} - VPC Peering is working correctly!        ║"
        FINAL_RESULT=0
    else
        echo -e "║  ${RED}SOME TESTS FAILED${NC} - Check security groups and routes        ║"
        FINAL_RESULT=1
    fi

    echo "╚══════════════════════════════════════════════════════════════════╝"
    exit $FINAL_RESULT
    SCRIPT

    chmod +x /home/ec2-user/test_connectivity.sh
    chown ec2-user:ec2-user /home/ec2-user/test_connectivity.sh
  EOF

  tags = {
    Name = "test-bastion-${var.name_suffix}"
    Role = "bastion"
  }
}

/**
 * VPC A Private Instance - Target in vpc_a private subnet
 *
 * This instance validates internal VPC routing.
 * No public IP (private subnet).
 */
resource "aws_instance" "vpc_a_private" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.vpc_a_private_subnet_id
  vpc_security_group_ids = [var.vpc_a_private_sg_id]

  tags = {
    Name = "test-vpc-a-private-${var.name_suffix}"
    Role = "target-same-vpc"
  }
}

/**
 * VPC B Private Instance - Target in vpc_b private subnet
 *
 * This instance validates cross-VPC connectivity via peering.
 * No public IP (private subnet in different VPC).
 */
resource "aws_instance" "vpc_b_private" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.vpc_b_private_subnet_id
  vpc_security_group_ids = [var.vpc_b_private_sg_id]

  tags = {
    Name = "test-vpc-b-private-${var.name_suffix}"
    Role = "target-cross-vpc"
  }
}
