/**
 * Outputs for KMS _test Module
 *
 * These values are needed by the Spring Boot applications:
 *   - company-backend: Uses key_arn to call KMS
 *   - client-simulator: Uses public_key_pem to encrypt data
 */

output "asymmetric_key_id" {
  description = "KMS Asymmetric Key ID"
  value       = aws_kms_key.asymmetric.key_id
}

output "asymmetric_key_arn" {
  description = "KMS Asymmetric Key ARN (use in company-backend application.yml)"
  value       = aws_kms_key.asymmetric.arn
}

output "asymmetric_key_alias" {
  description = "KMS Asymmetric Key Alias"
  value       = aws_kms_alias.asymmetric.name
}

# Instructions for getting the public key
output "public_key_command" {
  description = "Run this command to export the public key for 3rd party"
  value       = "aws kms get-public-key --key-id ${aws_kms_key.asymmetric.key_id} --query 'PublicKey' --output text | base64 -d > public_key.der"
}

output "usage_instructions" {
  description = "How to use this key"
  value       = <<-EOT

    ══════════════════════════════════════════════════════════════════
    USE-CASE 1: 3rd Party WITHOUT AWS Account
    ══════════════════════════════════════════════════════════════════

    1. Copy the key ARN to company-backend/src/main/resources/application.yml:
       ${aws_kms_key.asymmetric.arn}

    2. Start company-backend:
       cd ../usecase1-third-party-no-aws/company-backend
       ./gradlew bootRun

    3. Get public key (3rd party does this once):
       curl http://localhost:8080/api/v1/public-key

    4. Run client-simulator to test:
       cd ../client-simulator
       ./gradlew run

    ══════════════════════════════════════════════════════════════════
  EOT
}
