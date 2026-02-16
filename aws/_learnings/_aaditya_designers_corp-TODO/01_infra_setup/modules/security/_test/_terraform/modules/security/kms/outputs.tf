/**
 * KMS Module Outputs
 */

output "key_id" {
  description = "KMS Asymmetric Key ID"
  value       = aws_kms_key.asymmetric.key_id
}

output "key_arn" {
  description = "KMS Asymmetric Key ARN"
  value       = aws_kms_key.asymmetric.arn
}

output "key_alias" {
  description = "KMS Asymmetric Key Alias"
  value       = aws_kms_alias.asymmetric.name
}
