/**
 * Misc Internal Apps Secrets
 *
 * Stores credentials for internal productivity/collaboration apps:
 *   - GitLab: Source code management
 *   - Wiki.js: Documentation platform
 *
 * This module can be extended as more internal apps are added.
 */

# -----------------------------------------------------------------------------
# GitLab - Root Admin Secret
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "gitlab_root" {
  name                    = "${var.secret_path_prefix}/gitlab/root-password"
  description             = "GitLab root administrator password"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 0 # Force delete without recovery (POC only)

  tags = {
    Name        = "secret_gitlab_root-${var.name_suffix}"
    Application = "gitlab"
    Category    = "misc-internal"
  }
}

resource "aws_secretsmanager_secret_version" "gitlab_root" {
  secret_id = aws_secretsmanager_secret.gitlab_root.id
  secret_string = jsonencode({
    username = var.gitlab_username
    password = var.gitlab_password
  })
}

# -----------------------------------------------------------------------------
# Wiki.js - Admin Secret
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "wikijs_admin" {
  name                    = "${var.secret_path_prefix}/wikijs/admin-password"
  description             = "Wiki.js administrator password"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 0 # Force delete without recovery (POC only)

  tags = {
    Name        = "secret_wikijs_admin-${var.name_suffix}"
    Application = "wikijs"
    Category    = "misc-internal"
  }
}

resource "aws_secretsmanager_secret_version" "wikijs_admin" {
  secret_id = aws_secretsmanager_secret.wikijs_admin.id
  secret_string = jsonencode({
    username = var.wikijs_username
    password = var.wikijs_password
  })
}

# -----------------------------------------------------------------------------
# Future internal apps can be added here:
# - Jira, Confluence, Jenkins, SonarQube, etc.
# -----------------------------------------------------------------------------
