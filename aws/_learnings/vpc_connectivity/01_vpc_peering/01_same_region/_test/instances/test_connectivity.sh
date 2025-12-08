#!/bin/bash
#
# VPC Peering Connectivity Test Script
# Tests connectivity (ping) and bandwidth (iperf3) from VPC A private to VPC B private
#
# Usage:
#   ./test_connectivity.sh          # Run all tests (ping + bandwidth)
#   ./test_connectivity.sh ping     # Run ping tests only
#   ./test_connectivity.sh speed    # Run bandwidth tests only
#
# IPs are pre-configured by Terraform during instance creation
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Pre-configured target IP (injected by Terraform)
VPC_B_PRIVATE_IP="${vpc_b_private_ip}"

# Test mode (default: all)
TEST_MODE="$${1:-all}"

test_ping() {
    local target_ip=$1
    local target_name=$2

    echo -n "  Ping $target_name ($target_ip)... "

    if ping -c 3 -W 2 "$target_ip" > /dev/null 2>&1; then
        echo -e "$${GREEN}SUCCESS$${NC}"
        return 0
    else
        echo -e "$${RED}FAILED$${NC}"
        return 1
    fi
}

test_bandwidth() {
    local target_ip=$1
    local target_name=$2

    echo -e "  Testing bandwidth to $target_name ($target_ip)..."
    echo ""

    # Check if iperf3 is installed
    if ! command -v iperf3 &> /dev/null; then
        echo -e "  $${RED}ERROR: iperf3 not installed$${NC}"
        return 1
    fi

    # Run iperf3 test (5 second test)
    result=$(iperf3 -c "$target_ip" -t 5 2>&1)
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        # Get the summary line
        bandwidth=$(echo "$result" | grep "sender" | tail -1 | awk '{print $7, $8}')

        echo -e "  $${GREEN}SUCCESS$${NC}"
        echo -e "  Bandwidth: $${CYAN}$bandwidth$${NC}"
        echo ""
        return 0
    else
        echo -e "  $${RED}FAILED$${NC} - iperf3 server may not be running"
        echo "  Error: $(echo "$result" | head -1)"
        echo ""
        return 1
    fi
}

print_header() {
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║           VPC PEERING CONNECTIVITY TEST                          ║"
    echo "║        (VPC A Private -> VPC B Private via Peering)              ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Target IP (pre-configured by Terraform):"
    echo "  - VPC B Private: $VPC_B_PRIVATE_IP"
    echo ""
    echo "Test mode: $TEST_MODE"
    echo ""
}

run_ping_tests() {
    echo "┌──────────────────────────────────────────────────────────────────┐"
    echo "│ PING TEST                                                        │"
    echo "└──────────────────────────────────────────────────────────────────┘"
    echo ""
    echo "  Cross-VPC via Peering (VPC A Private -> VPC B Private)"
    test_ping "$VPC_B_PRIVATE_IP" "VPC B Private Instance"
    PING_RESULT=$?
    echo ""
}

run_bandwidth_tests() {
    echo "┌──────────────────────────────────────────────────────────────────┐"
    echo "│ BANDWIDTH TEST (iperf3)                                          │"
    echo "└──────────────────────────────────────────────────────────────────┘"
    echo ""
    echo "  Cross-VPC Bandwidth via Peering (VPC A Private -> VPC B Private)"
    test_bandwidth "$VPC_B_PRIVATE_IP" "VPC B Private Instance"
    BW_RESULT=$?
}

print_summary() {
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                         TEST SUMMARY                             ║"
    echo "╠══════════════════════════════════════════════════════════════════╣"

    local all_passed=true

    if [ "$TEST_MODE" = "all" ] || [ "$TEST_MODE" = "ping" ]; then
        if [ $PING_RESULT -eq 0 ]; then
            echo -e "║  Ping Test:       $${GREEN}PASSED$${NC}                                       ║"
        else
            echo -e "║  Ping Test:       $${RED}FAILED$${NC}                                       ║"
            all_passed=false
        fi
    fi

    if [ "$TEST_MODE" = "all" ] || [ "$TEST_MODE" = "speed" ]; then
        if [ $BW_RESULT -eq 0 ]; then
            echo -e "║  Bandwidth Test:  $${GREEN}PASSED$${NC}                                       ║"
        else
            echo -e "║  Bandwidth Test:  $${RED}FAILED$${NC}                                       ║"
            all_passed=false
        fi
    fi

    echo "╠══════════════════════════════════════════════════════════════════╣"

    if [ "$all_passed" = true ]; then
        echo -e "║  $${GREEN}ALL TESTS PASSED$${NC} - VPC Peering is working correctly!        ║"
        FINAL_RESULT=0
    else
        echo -e "║  $${RED}SOME TESTS FAILED$${NC} - Check security groups and routes        ║"
        FINAL_RESULT=1
    fi

    echo "╚══════════════════════════════════════════════════════════════════╝"
}

# Initialize result variables
PING_RESULT=0
BW_RESULT=0
FINAL_RESULT=0

# Main execution
print_header

case "$TEST_MODE" in
    ping)
        run_ping_tests
        ;;
    speed|bandwidth)
        run_bandwidth_tests
        ;;
    all|*)
        run_ping_tests
        run_bandwidth_tests
        ;;
esac

print_summary
exit $FINAL_RESULT
