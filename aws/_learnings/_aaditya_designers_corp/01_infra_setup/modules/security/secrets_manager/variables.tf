/**
 * Secrets Manager Module - Input Variables
 */

variable "kms_key_arn" {
  description = "ARN of the KMS key to encrypt secrets"
  type        = string
}

variable "name_suffix" {
  type        = string
  description = "Suffix for resource naming in the Region"
}

variable "component_version" {
  type        = string
  description = "Version tag for the component"
}

