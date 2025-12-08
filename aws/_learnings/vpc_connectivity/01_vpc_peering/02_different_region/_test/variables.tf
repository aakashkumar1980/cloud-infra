/**
 * Test Module Variables - Cross-Region
 *
 * Configuration for test EC2 instances that validate cross-region VPC peering connectivity.
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
  description = "VPC A CIDR block"
}

variable "vpc_c_cidr" {
  type        = string
  description = "VPC C CIDR block"
}

variable "name_suffix_nvirginia" {
  type        = string
  description = "Suffix for resource naming in N. Virginia"
}

variable "name_suffix_london" {
  type        = string
  description = "Suffix for resource naming in London"
}

variable "config_path" {
  type        = string
  description = "Path to amis.yaml configuration file"
}

variable "common_firewall_path" {
  type        = string
  description = "Path to common firewall.yaml configuration file"
}
