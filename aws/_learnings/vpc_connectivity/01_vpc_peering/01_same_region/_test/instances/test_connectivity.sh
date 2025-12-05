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
    echo -e "$${RED}Error: Both IP addresses are required$${NC}"
    echo "Usage: ./test_connectivity.sh <vpc_a_private_ip> <vpc_b_private_ip>"
    exit 1
fi

test_connectivity() {
    local target_ip=$1
    local target_name=$2

    echo -n "Testing $target_name ($target_ip)... "

    if ping -c 3 -W 2 "$target_ip" > /dev/null 2>&1; then
        echo -e "$${GREEN}SUCCESS$${NC} - Ping successful"
        return 0
    else
        echo -e "$${RED}FAILED$${NC} - No response"
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
    echo -e "║  $${GREEN}ALL TESTS PASSED$${NC} - VPC Peering is working correctly!        ║"
    FINAL_RESULT=0
else
    echo -e "║  $${RED}SOME TESTS FAILED$${NC} - Check security groups and routes        ║"
    FINAL_RESULT=1
fi

echo "╚══════════════════════════════════════════════════════════════════╝"
exit $FINAL_RESULT
