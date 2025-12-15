/**
 * KMS Module - Input Variables
 */

variable "nvirginia_region" {
  description = "AWS region for N. Virginia"
  type        = string
  default     = "us-east-1"
}

variable "london_region" {
  description = "AWS region for London"
  type        = string
  default     = "eu-west-2"
}

variable "name_suffix_nvirginia" {
  type        = string
  description = "Suffix for resource naming in N. Virginia"
}

variable "name_suffix_london" {
  type        = string
  description = "Suffix for resource naming in London"
}

# -----------------------------------------------------------------------------
# Key Reuse Configuration
# -----------------------------------------------------------------------------
variable "reuse_existing_keys" {
  description = "If true, looks up existing KMS keys by alias and reuses them instead of creating new ones"
  type        = bool
  default     = true
}

variable "prevent_destroy" {
  description = "If true, prevents KMS keys from being destroyed by terraform destroy"
  type        = bool
  default     = true
}
