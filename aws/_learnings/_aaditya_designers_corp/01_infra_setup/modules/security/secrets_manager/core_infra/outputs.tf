/**
 * Core Infrastructure Secrets - Outputs
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
# Keycloak Secret ARN
# -----------------------------------------------------------------------------
output "keycloak_admin_secret_arn" {
  description = "ARN of the Keycloak admin password secret"
  value       = aws_secretsmanager_secret.keycloak_admin.arn
}

# -----------------------------------------------------------------------------
# Apache Syncope Secret ARN
# -----------------------------------------------------------------------------
output "syncope_admin_secret_arn" {
  description = "ARN of the Apache Syncope admin password secret"
  value       = aws_secretsmanager_secret.syncope_admin.arn
}

# -----------------------------------------------------------------------------
# Grouped Outputs
# -----------------------------------------------------------------------------
output "ad_secret_arns" {
  description = "List of all AD-related secret ARNs"
  value = [
    aws_secretsmanager_secret.ad_admin.arn,
    aws_secretsmanager_secret.ad_restore.arn
  ]
}

output "all_secret_arns" {
  description = "List of all core infrastructure secret ARNs"
  value = [
    aws_secretsmanager_secret.ad_admin.arn,
    aws_secretsmanager_secret.ad_restore.arn,
    aws_secretsmanager_secret.keycloak_admin.arn,
    aws_secretsmanager_secret.syncope_admin.arn
  ]
}
