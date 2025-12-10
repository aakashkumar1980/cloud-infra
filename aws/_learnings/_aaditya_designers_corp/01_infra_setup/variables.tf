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
