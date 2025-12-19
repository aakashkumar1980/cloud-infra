/**
 * Data Sources for KMS Module
 *
 * Uses Terraform data sources to check if KMS key already exists in AWS.
 * This enables key reuse instead of recreation (KMS keys have 7-30 day deletion waiting period).
 */

# -----------------------------------------------------------------------------
# List all KMS Aliases and filter for our specific alias
# -----------------------------------------------------------------------------
data "aws_kms_aliases" "all" {}

locals {
  # The alias name we're looking for
  target_alias = "alias/test_asymmetric_kms-${var.name_suffix}"

  # Check if our alias exists in the list of all aliases
  kms_key_exists = contains(data.aws_kms_aliases.all.names, local.target_alias)

  # Get the alias details if it exists (for extracting key_id)
  matching_alias = local.kms_key_exists ? [
    for alias in data.aws_kms_aliases.all.aliases : alias
    if alias.name == local.target_alias
  ] : []

  existing_key_id = length(local.matching_alias) > 0 ? local.matching_alias[0].target_key_id : ""
}

# -----------------------------------------------------------------------------
# Data source to get existing KMS key details (only if key exists)
# -----------------------------------------------------------------------------
data "aws_kms_key" "existing" {
  count  = local.kms_key_exists ? 1 : 0
  key_id = local.target_alias
}
