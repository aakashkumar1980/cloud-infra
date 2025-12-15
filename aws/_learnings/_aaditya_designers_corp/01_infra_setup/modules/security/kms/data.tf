/**
 * KMS Module - Data Sources
 *
 * Minimal data sources for KMS key creation.
 * Keys are managed via Terraform state - no external lookups needed.
 */

# -----------------------------------------------------------------------------
# Current AWS Account
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {
  provider = aws.nvirginia
}
