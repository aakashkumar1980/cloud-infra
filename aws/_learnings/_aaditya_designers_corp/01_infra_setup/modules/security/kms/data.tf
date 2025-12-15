/**
 * KMS Module - Data Sources
 *
 * Looks up existing KMS keys by alias to enable key reuse.
 * Uses external data sources to safely check if aliases exist
 * before attempting to look them up (prevents errors on first run).
 *
 * Cross-platform support: Detects OS and uses appropriate shell
 * (bash for Linux/Mac, PowerShell for Windows)
 */

# -----------------------------------------------------------------------------
# Current AWS Account
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {
  provider = aws.nvirginia
}

# -----------------------------------------------------------------------------
# OS Detection
# Linux/Mac paths start with "/", Windows paths start with drive letter (e.g., "C:")
# -----------------------------------------------------------------------------
locals {
  is_windows = substr(pathexpand("~"), 0, 1) != "/"
}

# -----------------------------------------------------------------------------
# Check if KMS Aliases Exist (using AWS CLI)
# This prevents errors when aliases don't exist yet
# Cross-platform: Uses PowerShell on Windows, bash on Linux/Mac
# -----------------------------------------------------------------------------

# Check if N. Virginia alias exists (Windows)
data "external" "check_nvirginia_alias_windows" {
  count = local.is_windows ? 1 : 0

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

# Check if N. Virginia alias exists (Linux/Mac)
data "external" "check_nvirginia_alias_linux" {
  count = local.is_windows ? 0 : 1

  program = ["bash", "-c", <<-EOT
    if aws kms describe-key --key-id "alias/symmetric_kms-${var.name_suffix_nvirginia}" --region ${var.nvirginia_region} 2>/dev/null; then
      echo '{"exists": "true"}'
    else
      echo '{"exists": "false"}'
    fi
  EOT
  ]
}

# Check if London alias exists (Windows)
data "external" "check_london_alias_windows" {
  count = local.is_windows ? 1 : 0

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

# Check if London alias exists (Linux/Mac)
data "external" "check_london_alias_linux" {
  count = local.is_windows ? 0 : 1

  program = ["bash", "-c", <<-EOT
    if aws kms describe-key --key-id "alias/replica_symmetric_kms-${var.name_suffix_london}" --region ${var.london_region} 2>/dev/null; then
      echo '{"exists": "true"}'
    else
      echo '{"exists": "false"}'
    fi
  EOT
  ]
}

# Combine results from OS-specific checks
locals {
  nvirginia_alias_exists = local.is_windows ? (
    length(data.external.check_nvirginia_alias_windows) > 0 ? data.external.check_nvirginia_alias_windows[0].result.exists == "true" : false
  ) : (
    length(data.external.check_nvirginia_alias_linux) > 0 ? data.external.check_nvirginia_alias_linux[0].result.exists == "true" : false
  )

  london_alias_exists = local.is_windows ? (
    length(data.external.check_london_alias_windows) > 0 ? data.external.check_london_alias_windows[0].result.exists == "true" : false
  ) : (
    length(data.external.check_london_alias_linux) > 0 ? data.external.check_london_alias_linux[0].result.exists == "true" : false
  )
}

# -----------------------------------------------------------------------------
# Lookup Existing KMS Keys by Alias (only if they exist)
# -----------------------------------------------------------------------------

# Lookup N. Virginia key only if alias exists
data "aws_kms_alias" "existing_nvirginia" {
  provider = aws.nvirginia
  name     = "alias/symmetric_kms-${var.name_suffix_nvirginia}"

  count = local.nvirginia_alias_exists ? 1 : 0
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

  count = local.london_alias_exists ? 1 : 0
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
