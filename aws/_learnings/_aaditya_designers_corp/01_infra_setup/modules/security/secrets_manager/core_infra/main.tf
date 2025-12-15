/**
 * Core Infrastructure Secrets
 *
 * Stores credentials for core infrastructure applications:
 *   - AD DS: Domain Administrator, Safe Mode (DSRM) recovery
 *   - Keycloak: Identity and Access Management
 *   - Apache Syncope: Identity Governance
 *
 * These are critical infrastructure components.
 */

# -----------------------------------------------------------------------------
# AD DS - Domain Administrator Secret
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "ad_admin" {
  name                    = "${var.secret_path_prefix}/ad/admin-password"
  description             = "AD Domain Administrator password"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 0 # Force delete without recovery (POC only)

  tags = {
    Name        = "secret_ad_admin-${var.name_suffix}"
    Application = "active-directory"
    Category    = "core-infra"
  }
}

resource "aws_secretsmanager_secret_version" "ad_admin" {
  secret_id = aws_secretsmanager_secret.ad_admin.id
  secret_string = jsonencode({
    username = var.ad_admin_username
    password = var.ad_admin_password
    domain   = var.ad_domain
  })
}

# -----------------------------------------------------------------------------
# AD DS - Safe Mode (DSRM) Recovery Secret
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "ad_restore" {
  name                    = "${var.secret_path_prefix}/ad/restore-password"
  description             = "AD DS Safe Mode (DSRM) password for recovery"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 0 # Force delete without recovery (POC only)

  tags = {
    Name        = "secret_ad_restore-${var.name_suffix}"
    Application = "active-directory"
    Category    = "core-infra"
  }
}

resource "aws_secretsmanager_secret_version" "ad_restore" {
  secret_id = aws_secretsmanager_secret.ad_restore.id
  secret_string = jsonencode({
    password = var.ad_restore_password
    purpose  = "Directory Services Restore Mode"
  })
}

# -----------------------------------------------------------------------------
# Keycloak - Admin Secret
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "keycloak_admin" {
  name                    = "${var.secret_path_prefix}/keycloak/admin-password"
  description             = "Keycloak administrator password"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 0 # Force delete without recovery (POC only)

  tags = {
    Name        = "secret_keycloak_admin-${var.name_suffix}"
    Application = "keycloak"
    Category    = "core-infra"
  }
}

resource "aws_secretsmanager_secret_version" "keycloak_admin" {
  secret_id = aws_secretsmanager_secret.keycloak_admin.id
  secret_string = jsonencode({
    username = var.keycloak_username
    password = var.keycloak_password
  })
}

# -----------------------------------------------------------------------------
# Apache Syncope - Admin Secret
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "syncope_admin" {
  name                    = "${var.secret_path_prefix}/syncope/admin-password"
  description             = "Apache Syncope administrator password"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 0 # Force delete without recovery (POC only)

  tags = {
    Name        = "secret_syncope_admin-${var.name_suffix}"
    Application = "syncope"
    Category    = "core-infra"
  }
}

resource "aws_secretsmanager_secret_version" "syncope_admin" {
  secret_id = aws_secretsmanager_secret.syncope_admin.id
  secret_string = jsonencode({
    username = var.syncope_username
    password = var.syncope_password
  })
}
