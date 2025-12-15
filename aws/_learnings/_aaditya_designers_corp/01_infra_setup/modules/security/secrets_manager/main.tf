/**
 * Secrets Manager Module
 *
 * Securely stores sensitive credentials organized into two groups:
 *
 * 1. Core Infrastructure (core_infra/):
 *    - AD DS: Domain Administrator, Safe Mode (DSRM)
 *    - Keycloak: Identity and Access Management
 *    - Apache Syncope: Identity Governance
 *
 * 2. Misc Internal Apps (misc_internal/):
 *    - GitLab: Source code management
 *    - Wiki.js: Documentation platform
 *    - (Extensible for future apps)
 *
 * Features:
 *   - Encrypted with KMS Customer Managed Key
 *   - Auto-generated strong passwords (random_passwords.tf)
 *   - Centralized constants (locals.tf)
 *   - Secrets stored in N. Virginia (central location)
 *
 * Cost: ~$0.40/secret/month = ~$2.40/month for 6 secrets
 */

# -----------------------------------------------------------------------------
# Core Infrastructure Secrets (AD, Keycloak, Syncope)
# -----------------------------------------------------------------------------
module "core_infra" {
  source = "./core_infra"

  providers = {
    aws = aws.nvirginia
  }

  secret_path_prefix = local.secret_path_prefix
  name_suffix        = var.name_suffix
  kms_key_arn        = var.kms_key_arn

  # AD Configuration
  ad_admin_username   = local.ad_admin_username
  ad_admin_password   = random_password.ad_admin.result
  ad_restore_password = random_password.ad_restore.result
  ad_domain           = local.ad_domain

  # Keycloak Configuration
  keycloak_username = local.keycloak_username
  keycloak_password = random_password.keycloak_admin.result

  # Syncope Configuration
  syncope_username = local.syncope_username
  syncope_password = random_password.syncope_admin.result
}

# -----------------------------------------------------------------------------
# Misc Internal Apps Secrets (GitLab, Wiki.js, etc.)
# -----------------------------------------------------------------------------
module "misc_internal" {
  source = "./misc_internal"

  providers = {
    aws = aws.nvirginia
  }

  secret_path_prefix = local.secret_path_prefix
  name_suffix        = var.name_suffix
  kms_key_arn        = var.kms_key_arn

  # GitLab Configuration
  gitlab_username = local.gitlab_username
  gitlab_password = random_password.gitlab_root.result

  # Wiki.js Configuration
  wikijs_username = local.wikijs_username
  wikijs_password = random_password.wikijs_admin.result
}
