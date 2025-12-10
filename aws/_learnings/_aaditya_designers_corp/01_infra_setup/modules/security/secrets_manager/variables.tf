/**
 * Secrets Manager Module - Input Variables
 */

variable "kms_key_arn" {
  description = "ARN of the KMS key to encrypt secrets"
  type        = string
}

variable "tags_common" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
