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

# -----------------------------------------------------------------------------
# 1b. Secrets Manager Outputs
# -----------------------------------------------------------------------------
output "secrets" {
  description = "Secret ARNs (values are NOT exposed for security)"
  value = {
    ad = {
      admin_secret_arn   = module.secrets_manager.ad_admin_secret_arn
      restore_secret_arn = module.secrets_manager.ad_restore_secret_arn
    }
    gitlab = {
      root_secret_arn = module.secrets_manager.gitlab_root_secret_arn
    }
    wikijs = {
      admin_secret_arn = module.secrets_manager.wikijs_admin_secret_arn
    }
    keycloak = {
      admin_secret_arn = module.secrets_manager.keycloak_admin_secret_arn
    }
    syncope = {
      admin_secret_arn = module.secrets_manager.syncope_admin_secret_arn
    }
  }
}
