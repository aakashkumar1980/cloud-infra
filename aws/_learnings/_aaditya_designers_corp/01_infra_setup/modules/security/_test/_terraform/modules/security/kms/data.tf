/**
 * Data Sources for KMS Module
 *
 * Uses external data source to check if KMS key already exists in AWS.
 * This enables key reuse instead of recreation (KMS keys have 7-30 day deletion waiting period).
 */

# -----------------------------------------------------------------------------
# Check if KMS Key Already Exists (via Alias)
# -----------------------------------------------------------------------------
data "external" "check_kms_key" {
  program = ["powershell", "-ExecutionPolicy", "Bypass", "-File", "${path.module}/scripts/check_kms_key.ps1"]

  query = {
    alias_name = "alias/test_asymmetric_kms-${var.name_suffix}"
    profile    = var.profile
    region     = var.region
  }
}

locals {
  # Determine if KMS key already exists in AWS
  kms_key_exists = data.external.check_kms_key.result.exists == "true"
  existing_key_id = data.external.check_kms_key.result.key_id
}

# -----------------------------------------------------------------------------
# Data source to get existing KMS key details (only if key exists)
# -----------------------------------------------------------------------------
data "aws_kms_key" "existing" {
  count  = local.kms_key_exists ? 1 : 0
  key_id = "alias/test_asymmetric_kms-${var.name_suffix}"
}
