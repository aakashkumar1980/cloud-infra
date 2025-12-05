#!/bin/bash
#
# VPC Peering Connectivity Test Script
# Tests connectivity from bastion to private instances
#
# IPs are pre-configured by Terraform during instance creation
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Pre-configured target IPs (injected by Terraform)
VPC_A_PRIVATE_IP="${vpc_a_private_ip}"
VPC_B_PRIVATE_IP="${vpc_b_private_ip}"

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
echo "Target IPs (pre-configured by Terraform):"
echo "  - VPC A Private: $VPC_A_PRIVATE_IP"
echo "  - VPC B Private: $VPC_B_PRIVATE_IP"
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
