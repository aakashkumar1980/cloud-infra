#!/bin/bash
# ============================================================================
# Terraform Import Script for KMS Resources
# ============================================================================
#
# Purpose: Import existing KMS keys and aliases into Terraform state
#
# Use this script when:
#   - Terraform state files were accidentally deleted
#   - KMS resources exist in AWS but not in Terraform state
#   - You see "AlreadyExistsException" errors for KMS aliases during apply
#
# Prerequisites:
#   - AWS CLI installed and configured
#   - Terraform installed
#   - AWS profile "dev" configured with appropriate permissions
#
# Resources imported:
#   - aws_kms_key.kms_nvirginia (N. Virginia primary key)
#   - aws_kms_alias.kms_nvirginia (N. Virginia alias)
#   - aws_kms_replica_key.kms_london (London replica key)
#   - aws_kms_alias.kms_london (London alias)
#
# ============================================================================

set -e

echo "============================================"
echo "KMS Import Script for 01_infra_setup"
echo "============================================"

# Change to module directory
cd "$(dirname "$0")/.."

echo ""
echo "Initializing Terraform..."
terraform init
if [ $? -ne 0 ]; then
    echo "ERROR: Terraform init failed"
    exit 1
fi

echo ""
echo "============================================"
echo "Fetching existing KMS Key IDs from AWS..."
echo "============================================"

# Get N. Virginia key ID
echo ""
echo "[1/4] Getting N. Virginia KMS key ID..."
NVIRGINIA_KEY_ID=$(aws kms describe-key \
    --key-id alias/symmetric_kms-nvirginia-dev-aaditya_designers-terraform \
    --region us-east-1 \
    --profile dev \
    --query "KeyMetadata.KeyId" \
    --output text 2>/dev/null)

if [ -z "$NVIRGINIA_KEY_ID" ]; then
    echo "ERROR: Could not find N. Virginia KMS key. It may not exist."
    exit 1
fi
echo "Found: $NVIRGINIA_KEY_ID"

# Get London key ID
echo ""
echo "[2/4] Getting London KMS key ID..."
LONDON_KEY_ID=$(aws kms describe-key \
    --key-id alias/replica_symmetric_kms-london-dev-aaditya_designers-terraform \
    --region eu-west-2 \
    --profile dev \
    --query "KeyMetadata.KeyId" \
    --output text 2>/dev/null)

if [ -z "$LONDON_KEY_ID" ]; then
    echo "ERROR: Could not find London KMS key. It may not exist."
    exit 1
fi
echo "Found: $LONDON_KEY_ID"

echo ""
echo "============================================"
echo "Importing KMS resources into Terraform state..."
echo "============================================"

# Import N. Virginia KMS key
echo ""
echo "[1/4] Importing N. Virginia KMS key..."
terraform import -var="profile=dev" module.kms.aws_kms_key.kms_nvirginia "$NVIRGINIA_KEY_ID" || \
    echo "WARNING: Import may have failed or resource already exists in state"

# Import N. Virginia KMS alias
echo ""
echo "[2/4] Importing N. Virginia KMS alias..."
terraform import -var="profile=dev" module.kms.aws_kms_alias.kms_nvirginia \
    alias/symmetric_kms-nvirginia-dev-aaditya_designers-terraform || \
    echo "WARNING: Import may have failed or resource already exists in state"

# Import London KMS replica key
echo ""
echo "[3/4] Importing London KMS replica key..."
terraform import -var="profile=dev" module.kms.aws_kms_replica_key.kms_london "$LONDON_KEY_ID" || \
    echo "WARNING: Import may have failed or resource already exists in state"

# Import London KMS alias
echo ""
echo "[4/4] Importing London KMS alias..."
terraform import -var="profile=dev" module.kms.aws_kms_alias.kms_london \
    alias/replica_symmetric_kms-london-dev-aaditya_designers-terraform || \
    echo "WARNING: Import may have failed or resource already exists in state"

echo ""
echo "============================================"
echo "Running Terraform Plan to verify state..."
echo "============================================"
terraform plan -var="profile=dev"

echo ""
echo "============================================"
echo "Import completed!"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Review the plan output above"
echo "  2. If no changes needed, state is in sync"
echo "  3. Run apply.sh to continue with deployment"
echo ""
