/**
 * Global input variables.
 * network_config_path points to a JSON file we will read and decode.
 */
variable "project" {
  description = "Logical project name used in tags and resource names"
  type        = string
}

variable "env" {
  description = "Environment (e.g., dev/stage/prod)"
  type        = string
}

variable "owner" {
  description = "Owner tag for resources"
  type        = string
}

variable "network_config_path" {
  description = "Path to the JSON file with region/VPC/subnet definitions"
  type        = string
  default     = "${path.module}/config/network.json"
}

/**
 * Controls cost topology. If true, each VPC uses a single NAT gateway for all private subnets.
 * If false, NAT-per-AZ (higher resilience, higher cost).
 */
variable "single_nat_gateway" {
  description = "Cost flag: single NAT per VPC (true) or NAT per AZ (false)"
  type        = bool
  default     = true
}
