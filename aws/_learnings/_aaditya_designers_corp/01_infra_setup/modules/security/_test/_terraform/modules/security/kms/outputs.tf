/**
 * KMS Module Outputs
 * Uses existing resources if create_resources=false, otherwise uses newly created ones
 */

output "key_id" {
  description = "KMS Asymmetric Key ID"
  value       = var.create_resources ? aws_kms_key.asymmetric[0].key_id : data.aws_kms_alias.existing[0].target_key_id
}

output "key_arn" {
  description = "KMS Asymmetric Key ARN"
  value       = var.create_resources ? aws_kms_key.asymmetric[0].arn : data.aws_kms_alias.existing[0].target_key_arn
}

output "key_alias" {
  description = "KMS Asymmetric Key Alias"
  value       = var.create_resources ? aws_kms_alias.asymmetric[0].name : data.aws_kms_alias.existing[0].name
}
