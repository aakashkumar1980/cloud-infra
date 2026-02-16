/**
 * Core Infrastructure Secrets - Input Variables
 *
 * Secrets for: AD, Keycloak, Apache Syncope
 */

variable "secret_path_prefix" {
  description = "Prefix for secret names (e.g., /aaditya_designers)"
  type        = string
}

variable "name_suffix" {
  description = "Suffix for resource naming"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key to encrypt secrets"
  type        = string
}

# -----------------------------------------------------------------------------
# AD Configuration
# -----------------------------------------------------------------------------
variable "ad_admin_username" {
  description = "AD Administrator username"
  type        = string
}

variable "ad_admin_password" {
  description = "AD Administrator password"
  type        = string
  sensitive   = true
}

variable "ad_restore_password" {
  description = "AD DSRM restore password"
  type        = string
  sensitive   = true
}

variable "ad_domain" {
  description = "AD domain name"
  type        = string
}

# -----------------------------------------------------------------------------
# Keycloak Configuration
# -----------------------------------------------------------------------------
variable "keycloak_username" {
  description = "Keycloak admin username"
  type        = string
}

variable "keycloak_password" {
  description = "Keycloak admin password"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Apache Syncope Configuration
# -----------------------------------------------------------------------------
variable "syncope_username" {
  description = "Syncope admin username"
  type        = string
}

variable "syncope_password" {
  description = "Syncope admin password"
  type        = string
  sensitive   = true
}
