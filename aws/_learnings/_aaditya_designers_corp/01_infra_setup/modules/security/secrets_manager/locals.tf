/**
 * Secrets Manager Module - Local Variables
 *
 * Centralized constants for easy updates:
 *   - Company domain and secret path prefix
 *   - Application usernames
 *   - Password generation settings
 */

locals {
  # -------------------------------------------------------------------------
  # Company Configuration
  # -------------------------------------------------------------------------
  company_domain      = "aadityadesigners.com"
  secret_path_prefix  = "/aaditya_designers_${var.component_version}"

  # -------------------------------------------------------------------------
  # Password Generation Settings
  # -------------------------------------------------------------------------
  password_length          = 24
  password_special         = true
  password_override_special = "!@#$%^&*"

  # -------------------------------------------------------------------------
  # Core Infrastructure - Usernames
  # -------------------------------------------------------------------------
  ad_admin_username     = "Administrator"
  ad_domain             = "ad.${local.company_domain}"
  keycloak_username     = "admin"
  syncope_username      = "admin"

  # -------------------------------------------------------------------------
  # Misc Internal Apps - Usernames
  # -------------------------------------------------------------------------
  gitlab_username       = "root"
  wikijs_username       = "admin@${local.company_domain}"
}
