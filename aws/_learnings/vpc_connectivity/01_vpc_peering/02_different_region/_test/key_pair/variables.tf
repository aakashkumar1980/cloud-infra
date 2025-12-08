/**
 * Key Pair Module - Variables
 */

variable "name_suffix" {
  type        = string
  description = "Suffix for resource naming"
}

variable "public_key_openssh" {
  type        = string
  description = "Existing public key in OpenSSH format (for cross-region registration). If null, a new key pair will be generated."
  default     = null
}
