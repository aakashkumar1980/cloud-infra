/**
 * KMS Module - Outputs
 *
 * Exports key ARNs and IDs for use by other modules
 * (Secrets Manager, EC2 EBS encryption, CloudWatch Logs)
 */

# -----------------------------------------------------------------------------
# Symmetric KMS Key Outputs (N. Virginia)
# -----------------------------------------------------------------------------
output "nvirginia_key_arn" {
  description = "ARN of the symmetric KMS key in N. Virginia"
  value       = aws_kms_key.kms_nvirginia.arn
}

output "nvirginia_key_id" {
  description = "ID of the symmetric KMS key in N. Virginia"
  value       = aws_kms_key.kms_nvirginia.key_id
}

output "nvirginia_key_alias" {
  description = "Alias of the symmetric KMS key in N. Virginia"
  value       = aws_kms_alias.kms_nvirginia.name
}

# -----------------------------------------------------------------------------
# London KMS Key Outputs
# -----------------------------------------------------------------------------
output "london_key_arn" {
  description = "ARN of the KMS replica key in London"
  value       = aws_kms_replica_key.kms_london.arn
}

output "london_key_id" {
  description = "ID of the KMS replica key in London"
  value       = aws_kms_replica_key.kms_london.key_id
}

output "london_key_alias" {
  description = "Alias of the KMS replica key in London"
  value       = aws_kms_alias.kms_london.name
}
