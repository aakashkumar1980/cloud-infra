/**
 * KMS Module - Data Sources
 *
 * Looks up existing KMS keys by alias to enable key reuse.
 * Uses external data sources to safely check if aliases exist
 * before attempting to look them up (prevents errors on first run).
 */

# -----------------------------------------------------------------------------
# Current AWS Account
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {
  provider = aws.nvirginia
}

# -----------------------------------------------------------------------------
# Check if KMS Aliases Exist (using AWS CLI via PowerShell for Windows)
# This prevents errors when aliases don't exist yet
# -----------------------------------------------------------------------------

# Check if N. Virginia alias exists
data "external" "check_nvirginia_alias" {
  program = ["powershell", "-Command", <<-EOT
    $ErrorActionPreference = 'SilentlyContinue'
    $result = aws kms describe-key --key-id "alias/symmetric_kms-${var.name_suffix_nvirginia}" --region ${var.nvirginia_region} 2>$null
    if ($LASTEXITCODE -eq 0) {
      Write-Output '{"exists": "true"}'
    } else {
      Write-Output '{"exists": "false"}'
    }
  EOT
  ]
}

# Check if London alias exists
data "external" "check_london_alias" {
  program = ["powershell", "-Command", <<-EOT
    $ErrorActionPreference = 'SilentlyContinue'
    $result = aws kms describe-key --key-id "alias/replica_symmetric_kms-${var.name_suffix_london}" --region ${var.london_region} 2>$null
    if ($LASTEXITCODE -eq 0) {
      Write-Output '{"exists": "true"}'
    } else {
      Write-Output '{"exists": "false"}'
    }
  EOT
  ]
}

# -----------------------------------------------------------------------------
# Lookup Existing KMS Keys by Alias (only if they exist)
# -----------------------------------------------------------------------------

# Lookup N. Virginia key only if alias exists
data "aws_kms_alias" "existing_nvirginia" {
  provider = aws.nvirginia
  name     = "alias/symmetric_kms-${var.name_suffix_nvirginia}"

  count = data.external.check_nvirginia_alias.result.exists == "true" ? 1 : 0
}

# Get key details if alias exists
data "aws_kms_key" "existing_nvirginia" {
  provider = aws.nvirginia
  key_id   = data.aws_kms_alias.existing_nvirginia[0].target_key_id

  count = length(data.aws_kms_alias.existing_nvirginia) > 0 ? 1 : 0
}

# Lookup London replica key only if alias exists
data "aws_kms_alias" "existing_london" {
  provider = aws.london
  name     = "alias/replica_symmetric_kms-${var.name_suffix_london}"

  count = data.external.check_london_alias.result.exists == "true" ? 1 : 0
}

# Get key details if alias exists
data "aws_kms_key" "existing_london" {
  provider = aws.london
  key_id   = data.aws_kms_alias.existing_london[0].target_key_id

  count = length(data.aws_kms_alias.existing_london) > 0 ? 1 : 0
}

# -----------------------------------------------------------------------------
# Local Variables for Key Reuse Logic
# -----------------------------------------------------------------------------
locals {
  # Check if existing keys were found
  nvirginia_key_exists = length(data.aws_kms_key.existing_nvirginia) > 0
  london_key_exists    = length(data.aws_kms_key.existing_london) > 0

  # Final key ARNs (existing or newly created)
  nvirginia_key_arn = local.nvirginia_key_exists ? data.aws_kms_key.existing_nvirginia[0].arn : (length(aws_kms_key.kms_nvirginia) > 0 ? aws_kms_key.kms_nvirginia[0].arn : null)
  nvirginia_key_id  = local.nvirginia_key_exists ? data.aws_kms_key.existing_nvirginia[0].key_id : (length(aws_kms_key.kms_nvirginia) > 0 ? aws_kms_key.kms_nvirginia[0].key_id : null)

  london_key_arn = local.london_key_exists ? data.aws_kms_key.existing_london[0].arn : (length(aws_kms_replica_key.kms_london) > 0 ? aws_kms_replica_key.kms_london[0].arn : null)
  london_key_id  = local.london_key_exists ? data.aws_kms_key.existing_london[0].key_id : (length(aws_kms_replica_key.kms_london) > 0 ? aws_kms_replica_key.kms_london[0].key_id : null)
}
