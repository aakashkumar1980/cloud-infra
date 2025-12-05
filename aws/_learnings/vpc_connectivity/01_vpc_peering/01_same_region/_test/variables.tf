/**
 * Test Module Variables
 *
 * Configuration for test EC2 instances that validate VPC peering connectivity.
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
  description = "VPC A CIDR block"
}

variable "vpc_b_cidr" {
  type        = string
  description = "VPC B CIDR block"
}

variable "name_suffix" {
  type        = string
  description = "Suffix for resource naming"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name for SSH access"
  default     = ""
}

variable "config_path" {
  type        = string
  description = "Path to amis.yaml configuration file"
}

variable "common_firewall_path" {
  type        = string
  description = "Path to common firewall.yaml configuration file"
}

variable "region" {
  type        = string
  description = "Region key for AMI lookup (e.g., nvirginia, london)"
  default     = "nvirginia"
}
