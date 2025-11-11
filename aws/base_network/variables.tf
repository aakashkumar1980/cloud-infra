/**
 * Input Variables
 *
 * profile:
 *   - The AWS CLI profile to use (must exist in ~/.aws/credentials & ~/.aws/config)
 *   - Example: dev, qa, prod
 *   - Usage: terraform apply -var="profile=dev"
 */
variable "profile" {
  description = "Deployment environment profile (e.g., dev, stage, prod)"
  type        = string
}
