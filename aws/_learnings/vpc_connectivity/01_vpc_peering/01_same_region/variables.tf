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
