/**
 * IAM Module - KMS Decrypt-Only User
 *
 * Creates an IAM user with minimal permissions to decrypt using KMS.
 * Used by backend applications to call KMS.Decrypt API.
 */

variable "name_suffix" {
  description = "Name suffix for resources"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key this user can decrypt with"
  type        = string
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
