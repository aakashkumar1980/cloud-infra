/**
 * Security Groups Module - Variables
 */

variable "vpc_a_id" {
  type        = string
  description = "VPC A ID"
}

variable "vpc_b_id" {
  type        = string
  description = "VPC B ID"
}

variable "vpc_a_cidr" {
  type        = string
  description = "VPC A CIDR block (for ICMP rules)"
}

variable "vpc_b_cidr" {
  type        = string
  description = "VPC B CIDR block (for ICMP rules)"
}

variable "name_suffix" {
  type        = string
  description = "Suffix for resource naming"
}

variable "common_firewall_path" {
  type        = string
  description = "Path to common firewall.yaml configuration file"
}
