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

variable "tags_common" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
