/**
 * Infrastructure Outputs
 *
 * Exports key information for reference and use by other configurations.
 */

# =============================================================================
# PHASE 1: SECURITY FOUNDATION OUTPUTS
# =============================================================================

# -----------------------------------------------------------------------------
# 1a. KMS Outputs
# -----------------------------------------------------------------------------
output "kms" {
  description = "KMS encryption keys for both regions"
  value = {
    nvirginia = {
      key_arn   = module.kms.nvirginia_key_arn
      key_id    = module.kms.nvirginia_key_id
      key_alias = module.kms.nvirginia_key_alias
    }
    london = {
      key_arn   = module.kms.london_key_arn
      key_id    = module.kms.london_key_id
      key_alias = module.kms.london_key_alias
    }
  }
}
