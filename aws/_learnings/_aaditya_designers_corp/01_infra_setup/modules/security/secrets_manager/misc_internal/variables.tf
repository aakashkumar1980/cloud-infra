/**
 * Misc Internal Apps Secrets - Input Variables
 *
 * Secrets for: GitLab, Wiki.js, and future internal apps
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
# GitLab Configuration
# -----------------------------------------------------------------------------
variable "gitlab_username" {
  description = "GitLab root username"
  type        = string
}

variable "gitlab_password" {
  description = "GitLab root password"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Wiki.js Configuration
# -----------------------------------------------------------------------------
variable "wikijs_username" {
  description = "Wiki.js admin username/email"
  type        = string
}

variable "wikijs_password" {
  description = "Wiki.js admin password"
  type        = string
  sensitive   = true
}
