/**
 * Secrets Manager Module - Outputs
 *
 * Exports secret ARNs for use by IAM policies and EC2 instances.
 * NOTE: Actual secret values are NOT exposed here for security.
 */

# -----------------------------------------------------------------------------
# Core Infrastructure Secret ARNs
# -----------------------------------------------------------------------------
output "ad_admin_secret_arn" {
  description = "ARN of the AD admin password secret"
  value       = module.core_infra.ad_admin_secret_arn
}

output "ad_restore_secret_arn" {
  description = "ARN of the AD restore mode password secret"
  value       = module.core_infra.ad_restore_secret_arn
}

output "keycloak_admin_secret_arn" {
  description = "ARN of the Keycloak admin password secret"
  value       = module.core_infra.keycloak_admin_secret_arn
}

output "syncope_admin_secret_arn" {
  description = "ARN of the Apache Syncope admin password secret"
  value       = module.core_infra.syncope_admin_secret_arn
}

# -----------------------------------------------------------------------------
# Misc Internal Apps Secret ARNs
# -----------------------------------------------------------------------------
output "gitlab_root_secret_arn" {
  description = "ARN of the GitLab root password secret"
  value       = module.misc_internal.gitlab_root_secret_arn
}

output "wikijs_admin_secret_arn" {
  description = "ARN of the Wiki.js admin password secret"
  value       = module.misc_internal.wikijs_admin_secret_arn
}

# -----------------------------------------------------------------------------
# Grouped Outputs for IAM Policies
# -----------------------------------------------------------------------------
output "ad_secret_arns" {
  description = "List of all AD-related secret ARNs (for IAM policies)"
  value       = module.core_infra.ad_secret_arns
}

output "core_infra_secret_arns" {
  description = "List of all core infrastructure secret ARNs"
  value       = module.core_infra.all_secret_arns
}

output "misc_internal_secret_arns" {
  description = "List of all misc internal app secret ARNs"
  value       = module.misc_internal.all_secret_arns
}

output "all_secret_arns" {
  description = "List of all secret ARNs"
  value       = concat(
    module.core_infra.all_secret_arns,
    module.misc_internal.all_secret_arns
  )
}

# Backward compatibility alias
output "app_secret_arns" {
  description = "List of all application secret ARNs (for IAM policies) - Deprecated, use misc_internal_secret_arns"
  value       = module.misc_internal.all_secret_arns
}
