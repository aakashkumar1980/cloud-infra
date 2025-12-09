/**
 * Key Pair Module - Variables
 */

variable "name_suffix" {
  type        = string
  description = "Suffix for resource naming"
}

variable "public_key_openssh" {
  type        = string
  description = "Public key in OpenSSH format to register with AWS"
}
