/**
 * Input Variables
 *
 * Configuration for VPC peering between vpc_a and vpc_b in N. Virginia.
 */

variable "profile" {
  type        = string
  description = "Environment profile for loading configs (dev, stage, prod)"
  default     = "dev"
}

variable "name_suffix" {
  type        = string
  description = "Suffix for resource naming (should match base_network)"
  default     = "nvirginia-dev-terraform"
}

/** VPC names to look up from base_network */
variable "vpc_a_name" {
  type        = string
  description = "Name tag of vpc_a (requester VPC)"
  default     = "vpc_a-nvirginia-dev-terraform"
}

variable "vpc_b_name" {
  type        = string
  description = "Name tag of vpc_b (accepter VPC)"
  default     = "vpc_b-nvirginia-dev-terraform"
}

/** Test Module Configuration */
variable "enable_test" {
  type        = bool
  description = "Whether to create test EC2 instances for connectivity validation"
  default     = false
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name for SSH access to test instances"
  default     = ""
}

variable "my_ip" {
  type        = string
  description = "Your IP address for SSH access (CIDR format, e.g., 1.2.3.4/32)"
  default     = "0.0.0.0/0"
}
