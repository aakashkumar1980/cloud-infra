/**
 * KMS Module - Data Sources
 *
 * Looks up existing KMS keys by alias to enable key reuse.
 * This prevents creating duplicate keys and allows the module
 * to work with pre-existing keys.
 */

# -----------------------------------------------------------------------------
# Current AWS Account
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {
  provider = aws.nvirginia
}

# -----------------------------------------------------------------------------
# Lookup Existing KMS Keys by Alias (for reuse)
# -----------------------------------------------------------------------------

# Try to find existing N. Virginia key by alias
data "aws_kms_alias" "existing_nvirginia" {
  provider = aws.nvirginia
  name     = "alias/symmetric_kms-${var.name_suffix_nvirginia}"

  # Returns null if not found (won't fail)
  count = var.reuse_existing_keys ? 1 : 0
}

# Get key details if alias exists
data "aws_kms_key" "existing_nvirginia" {
  provider = aws.nvirginia
  key_id   = data.aws_kms_alias.existing_nvirginia[0].target_key_id

  count = var.reuse_existing_keys && length(data.aws_kms_alias.existing_nvirginia) > 0 ? 1 : 0
}

# Try to find existing London replica key by alias
data "aws_kms_alias" "existing_london" {
  provider = aws.london
  name     = "alias/replica_symmetric_kms-${var.name_suffix_london}"

  count = var.reuse_existing_keys ? 1 : 0
}

# Get key details if alias exists
data "aws_kms_key" "existing_london" {
  provider = aws.london
  key_id   = data.aws_kms_alias.existing_london[0].target_key_id

  count = var.reuse_existing_keys && length(data.aws_kms_alias.existing_london) > 0 ? 1 : 0
}

# -----------------------------------------------------------------------------
# Local Variables for Key Reuse Logic
# -----------------------------------------------------------------------------
locals {
  # Check if existing keys were found
  nvirginia_key_exists = var.reuse_existing_keys && length(data.aws_kms_key.existing_nvirginia) > 0
  london_key_exists    = var.reuse_existing_keys && length(data.aws_kms_key.existing_london) > 0

  # Final key ARNs (existing or newly created)
  nvirginia_key_arn = local.nvirginia_key_exists ? data.aws_kms_key.existing_nvirginia[0].arn : (length(aws_kms_key.kms_nvirginia) > 0 ? aws_kms_key.kms_nvirginia[0].arn : null)
  nvirginia_key_id  = local.nvirginia_key_exists ? data.aws_kms_key.existing_nvirginia[0].key_id : (length(aws_kms_key.kms_nvirginia) > 0 ? aws_kms_key.kms_nvirginia[0].key_id : null)

  london_key_arn = local.london_key_exists ? data.aws_kms_key.existing_london[0].arn : (length(aws_kms_replica_key.kms_london) > 0 ? aws_kms_replica_key.kms_london[0].arn : null)
  london_key_id  = local.london_key_exists ? data.aws_kms_key.existing_london[0].key_id : (length(aws_kms_replica_key.kms_london) > 0 ? aws_kms_replica_key.kms_london[0].key_id : null)
}
