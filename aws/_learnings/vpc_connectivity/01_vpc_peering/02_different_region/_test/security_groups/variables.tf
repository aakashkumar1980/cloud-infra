/**
 * Security Groups Module - Variables (Cross-Region)
 */

variable "vpc_a_id" {
  type        = string
  description = "VPC A ID (N. Virginia)"
}

variable "vpc_c_id" {
  type        = string
  description = "VPC C ID (London)"
}

variable "vpc_a_cidr" {
  type        = string
  description = "VPC A CIDR block (for security rules)"
}

variable "vpc_c_cidr" {
  type        = string
  description = "VPC C CIDR block (for security rules)"
}

variable "name_suffix_nvirginia" {
  type        = string
  description = "Suffix for resource naming in N. Virginia"
}

variable "name_suffix_london" {
  type        = string
  description = "Suffix for resource naming in London"
}

variable "common_firewall_path" {
  type        = string
  description = "Path to common firewall.yaml configuration file"
}
