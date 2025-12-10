/**
 * Secrets Manager Module - Outputs
 *
 * Exports secret ARNs for use by IAM policies and EC2 instances.
 * NOTE: Actual secret values are NOT exposed here for security.
 */

# -----------------------------------------------------------------------------
# AD DS Secret ARNs
# -----------------------------------------------------------------------------
output "ad_admin_secret_arn" {
  description = "ARN of the AD admin password secret"
  value       = aws_secretsmanager_secret.ad_admin.arn
}

output "ad_restore_secret_arn" {
  description = "ARN of the AD restore mode password secret"
  value       = aws_secretsmanager_secret.ad_restore.arn
}

# -----------------------------------------------------------------------------
# Application Secret ARNs
# -----------------------------------------------------------------------------
output "gitlab_root_secret_arn" {
  description = "ARN of the GitLab root password secret"
  value       = aws_secretsmanager_secret.gitlab_root.arn
}

output "wikijs_admin_secret_arn" {
  description = "ARN of the Wiki.js admin password secret"
  value       = aws_secretsmanager_secret.wikijs_admin.arn
}

output "keycloak_admin_secret_arn" {
  description = "ARN of the Keycloak admin password secret"
  value       = aws_secretsmanager_secret.keycloak_admin.arn
}

output "syncope_admin_secret_arn" {
  description = "ARN of the Apache Syncope admin password secret"
  value       = aws_secretsmanager_secret.syncope_admin.arn
}

# -----------------------------------------------------------------------------
# Grouped Outputs for IAM Policies
# -----------------------------------------------------------------------------
output "ad_secret_arns" {
  description = "List of all AD-related secret ARNs (for IAM policies)"
  value = [
    aws_secretsmanager_secret.ad_admin.arn,
    aws_secretsmanager_secret.ad_restore.arn
  ]
}

output "app_secret_arns" {
  description = "List of all application secret ARNs (for IAM policies)"
  value = [
    aws_secretsmanager_secret.gitlab_root.arn,
    aws_secretsmanager_secret.wikijs_admin.arn,
    aws_secretsmanager_secret.keycloak_admin.arn,
    aws_secretsmanager_secret.syncope_admin.arn
  ]
}

output "all_secret_arns" {
  description = "List of all secret ARNs"
  value = [
    aws_secretsmanager_secret.ad_admin.arn,
    aws_secretsmanager_secret.ad_restore.arn,
    aws_secretsmanager_secret.gitlab_root.arn,
    aws_secretsmanager_secret.wikijs_admin.arn,
    aws_secretsmanager_secret.keycloak_admin.arn,
    aws_secretsmanager_secret.syncope_admin.arn
  ]
}
