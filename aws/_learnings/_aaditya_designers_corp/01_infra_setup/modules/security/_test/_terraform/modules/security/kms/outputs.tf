/**
 * KMS Module Outputs
 *
 * NOTE: These outputs work for both new and existing KMS keys.
 * The module automatically detects and reuses existing keys.
 */

output "key_id" {
  description = "KMS Asymmetric Key ID (new or existing)"
  value       = local.effective_key_id
}

output "key_arn" {
  description = "KMS Asymmetric Key ARN (new or existing)"
  value       = local.effective_key_arn
}

output "key_alias" {
  description = "KMS Asymmetric Key Alias"
  value       = local.effective_key_alias
}

output "key_reused" {
  description = "Whether an existing KMS key was reused"
  value       = local.kms_key_exists
}
