# AWS CLI profile to use (must exist in ~/.aws/credentials)
variable "profile" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}
