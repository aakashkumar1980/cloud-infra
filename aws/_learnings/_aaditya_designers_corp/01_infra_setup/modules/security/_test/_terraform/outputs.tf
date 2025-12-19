/**
 * Outputs for KMS _test Module
 *
 * These values are needed by the Spring Boot applications:
 *   - company-backend: Uses key_arn and IAM credentials to call KMS
 *   - client-simulator: Uses public_key_pem to encrypt data
 */

# -----------------------------------------------------------------------------
# KMS Outputs
# -----------------------------------------------------------------------------
output "asymmetric_key_id" {
  description = "KMS Asymmetric Key ID"
  value       = module.kms.key_id
}

output "asymmetric_key_arn" {
  description = "KMS Asymmetric Key ARN (use in company-backend application.yml)"
  value       = module.kms.key_arn
}

output "asymmetric_key_alias" {
  description = "KMS Asymmetric Key Alias"
  value       = module.kms.key_alias
}

output "asymmetric_key_reused" {
  description = "Whether an existing KMS key was reused (true) or new key created (false)"
  value       = module.kms.key_reused
}

# -----------------------------------------------------------------------------
# IAM Outputs - For Backend Application
# -----------------------------------------------------------------------------
output "iam_user_name" {
  description = "IAM User name for KMS decrypt operations"
  value       = module.iam.user_name
}

output "iam_user_arn" {
  description = "IAM User ARN"
  value       = module.iam.user_arn
}

output "iam_access_key_id" {
  description = "AWS Access Key ID for the backend application"
  value       = module.iam.access_key_id
}

output "iam_secret_access_key" {
  description = "AWS Secret Access Key for the backend application (sensitive)"
  value       = module.iam.secret_access_key
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Instructions
# -----------------------------------------------------------------------------
output "public_key_command" {
  description = "Run this command to export the public key for 3rd party"
  value       = "aws kms get-public-key --key-id ${module.kms.key_id} --query 'PublicKey' --output text | base64 -d > public_key.der"
}

output "usage_instructions" {
  description = "How to use this key"
  value       = <<-EOT

    ══════════════════════════════════════════════════════════════════
    USE-CASE 1: 3rd Party WITHOUT AWS Account
    ══════════════════════════════════════════════════════════════════

    1. Get IAM credentials for the backend application:
       terraform output iam_access_key_id
       terraform output -raw iam_secret_access_key

    2. Run the application with credentials:
       AWS_ACCESS_KEY_ID=$(terraform output -raw iam_access_key_id) \
       AWS_SECRET_ACCESS_KEY=$(terraform output -raw iam_secret_access_key) \
       AWS_KMS_ASYMMETRIC_KEY_ARN=${module.kms.key_arn} \
       ./gradlew bootRun

    3. Get public key (3rd party does this once):
       curl http://localhost:8080/api/v1/public-key

    4. Run client-simulator to test:
       cd ../client-simulator
       ./gradlew run

    ══════════════════════════════════════════════════════════════════
  EOT
}
