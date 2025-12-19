/**
 * KMS Module - Asymmetric Key for 3rd Party Encryption
 *
 * Creates an RSA-4096 asymmetric key pair:
 *   - Public Key:  Exported and shared with 3rd party clients
 *   - Private Key: Never leaves KMS, used for decryption
 *
 * NOTE: If the KMS key already exists in AWS, it will be reused (not recreated).
 */

variable "name_suffix" {
  description = "Name suffix for resources"
  type        = string
}

variable "key_deletion_window" {
  description = "Number of days before KMS key is deleted"
  type        = number
  default     = 7
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "profile" {
  description = "AWS CLI profile name for checking existing resources"
  type        = string
}

variable "region" {
  description = "AWS region for checking existing resources"
  type        = string
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
