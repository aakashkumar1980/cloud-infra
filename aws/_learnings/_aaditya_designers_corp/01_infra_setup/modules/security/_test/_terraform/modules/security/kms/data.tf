/**
 * Data Sources for KMS Module
 *
 * Uses external data source to check if KMS key already exists in AWS.
 * This enables key reuse instead of recreation (KMS keys have 7-30 day deletion waiting period).
 */

locals {
  # The alias name we're looking for
  target_alias = "alias/test_asymmetric_kms-${var.name_suffix}"
}

# -----------------------------------------------------------------------------
# Check if KMS Alias exists using AWS CLI (via external data source)
# -----------------------------------------------------------------------------
data "external" "check_kms_alias" {
  program = ["powershell", "-Command", <<-EOT
    $alias = "${local.target_alias}"
    $region = "${var.region}"
    try {
      $result = aws kms describe-key --key-id $alias --region $region 2>$null | ConvertFrom-Json
      if ($result.KeyMetadata.KeyState -eq "Enabled") {
        @{ exists = "true"; key_id = $result.KeyMetadata.KeyId } | ConvertTo-Json -Compress
      } else {
        @{ exists = "false"; key_id = "" } | ConvertTo-Json -Compress
      }
    } catch {
      @{ exists = "false"; key_id = "" } | ConvertTo-Json -Compress
    }
  EOT
  ]
}

locals {
  # Check if our alias exists in AWS
  kms_key_exists  = data.external.check_kms_alias.result.exists == "true"
  existing_key_id = data.external.check_kms_alias.result.key_id
}

# -----------------------------------------------------------------------------
# Data source to get existing KMS key details (only if key exists)
# -----------------------------------------------------------------------------
data "aws_kms_key" "existing" {
  count  = local.kms_key_exists ? 1 : 0
  key_id = local.target_alias
}
