/**
 * Secrets Manager Module - Random Password Generation
 *
 * Auto-generates strong passwords for all applications.
 * Settings are defined in locals.tf for consistency.
 */

# -----------------------------------------------------------------------------
# Core Infrastructure Passwords
# -----------------------------------------------------------------------------
resource "random_password" "ad_admin" {
  length           = local.password_length
  special          = local.password_special
  override_special = local.password_override_special
}

resource "random_password" "ad_restore" {
  length           = local.password_length
  special          = local.password_special
  override_special = local.password_override_special
}

resource "random_password" "keycloak_admin" {
  length           = local.password_length
  special          = local.password_special
  override_special = local.password_override_special
}

resource "random_password" "syncope_admin" {
  length           = local.password_length
  special          = local.password_special
  override_special = local.password_override_special
}

# -----------------------------------------------------------------------------
# Misc Internal App Passwords
# -----------------------------------------------------------------------------
resource "random_password" "gitlab_root" {
  length           = local.password_length
  special          = local.password_special
  override_special = local.password_override_special
}

resource "random_password" "wikijs_admin" {
  length           = local.password_length
  special          = local.password_special
  override_special = local.password_override_special
}
