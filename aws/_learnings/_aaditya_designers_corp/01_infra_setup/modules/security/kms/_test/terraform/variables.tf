/**
 * Input Variables for KMS _test Module
 */
variable "profile" {
  description = "AWS profile to use (matches ~/.aws/credentials profile name)"
  type        = string
  default     = "dev"
}

variable "key_deletion_window" {
  description = "Number of days before KMS key is deleted (7-30)"
  type        = number
  default     = 7
}
