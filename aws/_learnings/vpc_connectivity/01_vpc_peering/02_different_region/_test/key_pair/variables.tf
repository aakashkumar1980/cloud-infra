/**
 * Key Pair Module - Variables
 */

variable "name_suffix" {
  type        = string
  description = "Suffix for resource naming"
}

variable "public_key_openssh" {
  type        = string
  description = "Existing public key in OpenSSH format to import (if provided, skips key generation)"
  default     = null
}
