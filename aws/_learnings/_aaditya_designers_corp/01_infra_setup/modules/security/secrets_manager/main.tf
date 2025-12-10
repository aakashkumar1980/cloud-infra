/**
 * Secrets Manager Module
 *
 * Securely stores sensitive credentials for:
 *   - AD DS: Domain Administrator password, Safe Mode password
 *   - GitLab: Root admin password
 *   - Wiki.js: Admin password
 *   - Keycloak: Admin password
 *   - Apache Syncope: Admin password
 *
 * Features:
 *   - Encrypted with KMS Customer Managed Key
 *   - Auto-generated strong passwords
 *   - Secrets stored in N. Virginia (central location)
 *
 * Cost: ~$0.40/secret/month = ~$2.40/month for 6 secrets
 */

# -----------------------------------------------------------------------------
# Random Password Generator
# -----------------------------------------------------------------------------
resource "random_password" "ad_admin" {
  length           = 24
  special          = true
  override_special = "!@#$%^&*"
}

resource "random_password" "ad_restore" {
  length           = 24
  special          = true
  override_special = "!@#$%^&*"
}

resource "random_password" "gitlab_root" {
  length           = 24
  special          = true
  override_special = "!@#$%^&*"
}

resource "random_password" "wikijs_admin" {
  length           = 24
  special          = true
  override_special = "!@#$%^&*"
}

resource "random_password" "keycloak_admin" {
  length           = 24
  special          = true
  override_special = "!@#$%^&*"
}

resource "random_password" "syncope_admin" {
  length           = 24
  special          = true
  override_special = "!@#$%^&*"
}

# -----------------------------------------------------------------------------
# AD DS Secrets
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "ad_admin" {
  provider = aws.nvirginia

  name        = "/aaditya/ad/admin-password"
  description = "AD Domain Administrator password"
  kms_key_id  = var.kms_key_arn

  tags = merge(var.tags_common, {
    Name        = "aaditya-ad-admin-password"
    Application = "active-directory"
  })
}

resource "aws_secretsmanager_secret_version" "ad_admin" {
  provider = aws.nvirginia

  secret_id = aws_secretsmanager_secret.ad_admin.id
  secret_string = jsonencode({
    username = "Administrator"
    password = random_password.ad_admin.result
    domain   = "ad.aadityadesigners.com"
  })
}

resource "aws_secretsmanager_secret" "ad_restore" {
  provider = aws.nvirginia

  name        = "/aaditya/ad/restore-password"
  description = "AD DS Safe Mode (DSRM) password for recovery"
  kms_key_id  = var.kms_key_arn

  tags = merge(var.tags_common, {
    Name        = "aaditya-ad-restore-password"
    Application = "active-directory"
  })
}

resource "aws_secretsmanager_secret_version" "ad_restore" {
  provider = aws.nvirginia

  secret_id = aws_secretsmanager_secret.ad_restore.id
  secret_string = jsonencode({
    password = random_password.ad_restore.result
    purpose  = "Directory Services Restore Mode"
  })
}

# -----------------------------------------------------------------------------
# GitLab Secret
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "gitlab_root" {
  provider = aws.nvirginia

  name        = "/aaditya/gitlab/root-password"
  description = "GitLab root administrator password"
  kms_key_id  = var.kms_key_arn

  tags = merge(var.tags_common, {
    Name        = "aaditya-gitlab-root-password"
    Application = "gitlab"
  })
}

resource "aws_secretsmanager_secret_version" "gitlab_root" {
  provider = aws.nvirginia

  secret_id = aws_secretsmanager_secret.gitlab_root.id
  secret_string = jsonencode({
    username = "root"
    password = random_password.gitlab_root.result
  })
}

# -----------------------------------------------------------------------------
# Wiki.js Secret
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "wikijs_admin" {
  provider = aws.nvirginia

  name        = "/aaditya/wikijs/admin-password"
  description = "Wiki.js administrator password"
  kms_key_id  = var.kms_key_arn

  tags = merge(var.tags_common, {
    Name        = "aaditya-wikijs-admin-password"
    Application = "wikijs"
  })
}

resource "aws_secretsmanager_secret_version" "wikijs_admin" {
  provider = aws.nvirginia

  secret_id = aws_secretsmanager_secret.wikijs_admin.id
  secret_string = jsonencode({
    username = "admin@aadityadesigners.com"
    password = random_password.wikijs_admin.result
  })
}

# -----------------------------------------------------------------------------
# Keycloak Secret
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "keycloak_admin" {
  provider = aws.nvirginia

  name        = "/aaditya/keycloak/admin-password"
  description = "Keycloak administrator password"
  kms_key_id  = var.kms_key_arn

  tags = merge(var.tags_common, {
    Name        = "aaditya-keycloak-admin-password"
    Application = "keycloak"
  })
}

resource "aws_secretsmanager_secret_version" "keycloak_admin" {
  provider = aws.nvirginia

  secret_id = aws_secretsmanager_secret.keycloak_admin.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.keycloak_admin.result
  })
}

# -----------------------------------------------------------------------------
# Apache Syncope Secret
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "syncope_admin" {
  provider = aws.nvirginia

  name        = "/aaditya/syncope/admin-password"
  description = "Apache Syncope administrator password"
  kms_key_id  = var.kms_key_arn

  tags = merge(var.tags_common, {
    Name        = "aaditya-syncope-admin-password"
    Application = "syncope"
  })
}

resource "aws_secretsmanager_secret_version" "syncope_admin" {
  provider = aws.nvirginia

  secret_id = aws_secretsmanager_secret.syncope_admin.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.syncope_admin.result
  })
}
