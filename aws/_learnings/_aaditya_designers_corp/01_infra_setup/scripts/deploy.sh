#!/bin/bash
#
# Aaditya Designers Corp - Infrastructure Deployment Script
#
# This script automates the deployment of all required infrastructure
# in the correct order:
#   1. Base Network (VPCs, Subnets, NAT, IGW)
#   2. VPC Peering - Same Region (VPC A <-> VPC B)
#   3. VPC Peering - Cross Region (N. Virginia <-> London)
#   4. This Infrastructure (Security, Compute, etc.)
#
# Usage:
#   ./scripts/deploy.sh [action] [profile]
#
# Actions:
#   apply   - Deploy all infrastructure (default)
#   destroy - Destroy all infrastructure (reverse order)
#   plan    - Plan only, no changes
#
# Profile:
#   dev     - Development environment (default)
#   stage   - Staging environment
#   prod    - Production environment
#
# Examples:
#   ./scripts/deploy.sh apply dev
#   ./scripts/deploy.sh destroy dev
#   ./scripts/deploy.sh plan dev
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ACTION="${1:-apply}"
PROFILE="${2:-dev}"
# New: optional third arg (--force or -f) to skip confirmation for destroy
FORCE_FLAG="${3:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"

# Module paths (relative to PROJECT_ROOT)
BASE_NETWORK="${PROJECT_ROOT}/aws/base_network"
VPC_PEERING_SAME="${PROJECT_ROOT}/aws/_learnings/vpc_connectivity/01_vpc_peering/01_same_region"
VPC_PEERING_CROSS="${PROJECT_ROOT}/aws/_learnings/vpc_connectivity/01_vpc_peering/02_different_region"
INFRA_SETUP="${PROJECT_ROOT}/aws/_learnings/_aaditya_designers_corp/01_infra_setup"

# Function to print colored output
print_header() {
    echo -e "\n${BLUE}============================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}============================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to run terraform in a directory
run_terraform() {
    local dir="$1"
    local action="$2"
    local name="$3"

    print_header "$name"
    echo "Directory: $dir"
    echo "Action: $action"
    echo "Profile: $PROFILE"
    echo ""

    cd "$dir"

    # Initialize if needed
    if [ ! -d ".terraform" ]; then
        echo "Initializing Terraform..."
        terraform init
    fi

    case "$action" in
        plan)
            terraform plan -var="profile=${PROFILE}"
            ;;
        apply)
            terraform apply -var="profile=${PROFILE}" -auto-approve
            ;;
        destroy)
            terraform destroy -var="profile=${PROFILE}" -auto-approve
            ;;
        *)
            print_error "Unknown action: $action"
            exit 1
            ;;
    esac

    print_success "$name completed!"
}

# Validate action
if [[ ! "$ACTION" =~ ^(apply|destroy|plan)$ ]]; then
    print_error "Invalid action: $ACTION"
    echo "Valid actions: apply, destroy, plan"
    exit 1
fi

# Validate profile
if [[ ! "$PROFILE" =~ ^(dev|stage|prod)$ ]]; then
    print_error "Invalid profile: $PROFILE"
    echo "Valid profiles: dev, stage, prod"
    exit 1
fi

# Check terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed!"
    echo "Please install Terraform: https://www.terraform.io/downloads"
    exit 1
fi

print_header "Aaditya Designers Corp - Infrastructure Deployment"
echo "Action:  $ACTION"
echo "Profile: $PROFILE"
echo "Project Root: $PROJECT_ROOT"
echo "Force:   $FORCE_FLAG"

# Confirm destroy action (skip if FORCE_FLAG is --force or -f)
if [ "$ACTION" == "destroy" ] && [ "$FORCE_FLAG" != "--force" ] && [ "$FORCE_FLAG" != "-f" ]; then
    print_warning "This will DESTROY all infrastructure!"
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Aborted."
        exit 0
    fi
fi

# Execute based on action
if [ "$ACTION" == "destroy" ]; then
    # Destroy in REVERSE order
    run_terraform "$INFRA_SETUP" "destroy" "Step 4/4: Infrastructure Setup"
    run_terraform "$VPC_PEERING_CROSS" "destroy" "Step 3/4: VPC Peering (Cross-Region)"
    run_terraform "$VPC_PEERING_SAME" "destroy" "Step 2/4: VPC Peering (Same Region)"
    run_terraform "$BASE_NETWORK" "destroy" "Step 1/4: Base Network"
else
    # Apply/Plan in FORWARD order
    run_terraform "$BASE_NETWORK" "$ACTION" "Step 1/4: Base Network"
    run_terraform "$VPC_PEERING_SAME" "$ACTION" "Step 2/4: VPC Peering (Same Region)"
    run_terraform "$VPC_PEERING_CROSS" "$ACTION" "Step 3/4: VPC Peering (Cross-Region)"
    run_terraform "$INFRA_SETUP" "$ACTION" "Step 4/4: Infrastructure Setup"
fi

print_header "Deployment Complete!"
echo -e "${GREEN}All steps completed successfully!${NC}"
