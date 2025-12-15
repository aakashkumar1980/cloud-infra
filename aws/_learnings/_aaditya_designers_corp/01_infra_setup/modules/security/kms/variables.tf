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