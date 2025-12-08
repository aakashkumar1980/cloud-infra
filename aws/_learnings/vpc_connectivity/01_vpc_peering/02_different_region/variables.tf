/**
 * Input Variables
 *
 * Configuration for cross-region VPC peering between:
 *   - N. Virginia (us-east-1): vpc_a
 *   - London (eu-west-2):      vpc_c
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
