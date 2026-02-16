/**
 * Input Variables
 *
 * Defines the configurable parameters for the infrastructure setup.
 */

variable "profile" {
  description = "AWS profile to use (dev, stage, prod)"
  type        = string
  default     = "dev"
}

/** Test Module Configuration */
variable "enable_test" {
  type        = bool
  description = "Whether to create test EC2 instances for connectivity validation"
  default     = false
}
