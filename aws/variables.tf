/**
 * Path to JSON file with network definitions. This file contains region, VPC CIDR, and subnet CIDRs.
 * See config/network.json for an example structure.
 */
variable "network_config_path" {
  description = "Path to the JSON file with region/VPC/subnet definitions"
  type        = string
  default     = "./config/network.json"
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
