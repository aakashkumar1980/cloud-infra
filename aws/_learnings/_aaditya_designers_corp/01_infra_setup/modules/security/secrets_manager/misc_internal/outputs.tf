/**
 * Misc Internal Apps Secrets - Outputs
 */

# -----------------------------------------------------------------------------
# GitLab Secret ARN
# -----------------------------------------------------------------------------
output "gitlab_root_secret_arn" {
  description = "ARN of the GitLab root password secret"
  value       = aws_secretsmanager_secret.gitlab_root.arn
}

# -----------------------------------------------------------------------------
# Wiki.js Secret ARN
# -----------------------------------------------------------------------------
output "wikijs_admin_secret_arn" {
  description = "ARN of the Wiki.js admin password secret"
  value       = aws_secretsmanager_secret.wikijs_admin.arn
}

# -----------------------------------------------------------------------------
# Grouped Output
# -----------------------------------------------------------------------------
output "all_secret_arns" {
  description = "List of all misc internal app secret ARNs"
  value = [
    aws_secretsmanager_secret.gitlab_root.arn,
    aws_secretsmanager_secret.wikijs_admin.arn
  ]
}
