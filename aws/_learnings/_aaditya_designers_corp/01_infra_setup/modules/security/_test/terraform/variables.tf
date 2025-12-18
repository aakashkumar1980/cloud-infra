/**
 * Input Variables for KMS _test Module
 */
variable "profile" {
  description = "AWS profile to use (matches ~/.aws/credentials profile name)"
  type        = string
  default     = "dev"
}

variable "key_deletion_window" {
  description = "Number of days before KMS key is deleted. AWS enforces minimum 7 days (cannot be 0 like Secrets Manager)"
  type        = number
  default     = 7 # Minimum allowed by AWS for KMS keys
}
