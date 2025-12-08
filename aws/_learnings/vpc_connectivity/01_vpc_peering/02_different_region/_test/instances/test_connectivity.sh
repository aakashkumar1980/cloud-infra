#!/bin/bash
#
# Cross-Region VPC Peering Connectivity Test Script
# Tests connectivity (ping) and bandwidth (iperf3) from VPC A private to VPC C private
#
# Usage:
#   ./test_connectivity.sh          # Run all tests (ping + bandwidth)
#   ./test_connectivity.sh ping     # Run ping tests only
#   ./test_connectivity.sh speed    # Run bandwidth tests only
#
# IPs are pre-configured by Terraform during instance creation
#
# Cross-Region Notes:
#   - Cross-region (N. Virginia -> London) latency: ~60-100ms
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Pre-configured target IP (injected by Terraform)
VPC_C_PRIVATE_IP="${vpc_c_private_ip}"

# Test mode (default: all)
TEST_MODE="$${1:-all}"

test_ping() {
    local target_ip=$1
    local target_name=$2
    local expected_latency=$3

    echo -n "  Ping $target_name ($target_ip)... "

    # Run ping and capture output for latency
    ping_output=$(ping -c 3 -W 2 "$target_ip" 2>&1)
    ping_result=$?

    if [ $ping_result -eq 0 ]; then
        # Extract average latency
        avg_latency=$(echo "$ping_output" | grep -oP 'rtt min/avg/max/mdev = \K[0-9.]+/([0-9.]+)' | cut -d'/' -f2)
        echo -e "$${GREEN}SUCCESS$${NC} (avg: $${CYAN}$${avg_latency}ms$${NC}, expected: $expected_latency)"
        return 0
    else
        echo -e "$${RED}FAILED$${NC}"
        return 1
    fi
}

test_bandwidth() {
    local target_ip=$1
    local target_name=$2
    local region=$3

    echo -e "  Testing bandwidth to $target_name ($target_ip) [$region]..."
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
    echo "║      CROSS-REGION VPC PEERING CONNECTIVITY TEST                  ║"
    echo "║    (VPC A Private N.Virginia -> VPC C Private London)            ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Target IP (pre-configured by Terraform):"
    echo "  - VPC C Private (London): $VPC_C_PRIVATE_IP"
    echo ""
    echo "Test mode: $TEST_MODE"
    echo ""
}

run_ping_tests() {
    echo "┌──────────────────────────────────────────────────────────────────┐"
    echo "│ PING TEST                                                        │"
    echo "└──────────────────────────────────────────────────────────────────┘"
    echo ""
    echo "  Cross-Region via Peering (VPC A Private -> VPC C Private)"
    test_ping "$VPC_C_PRIVATE_IP" "VPC C Private Instance (London)" "~60-100ms"
    PING_RESULT=$?
    echo ""
}

run_bandwidth_tests() {
    echo "┌──────────────────────────────────────────────────────────────────┐"
    echo "│ BANDWIDTH TEST (iperf3)                                          │"
    echo "└──────────────────────────────────────────────────────────────────┘"
    echo ""
    echo "  Cross-Region Bandwidth via Peering (VPC A Private -> VPC C Private)"
    test_bandwidth "$VPC_C_PRIVATE_IP" "VPC C Private Instance" "London"
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
        echo -e "║  $${GREEN}ALL TESTS PASSED$${NC} - Cross-region VPC Peering is working!     ║"
        FINAL_RESULT=0
    else
        echo -e "║  $${RED}SOME TESTS FAILED$${NC} - Check security groups and routes        ║"
        FINAL_RESULT=1
    fi

    echo "╠══════════════════════════════════════════════════════════════════╣"
    echo "║  Expected Latency: ~60-100ms (cross-region)                      ║"
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
