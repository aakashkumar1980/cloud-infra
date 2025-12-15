/**
 * KMS Module - Outputs
 *
 * Exports key ARNs and IDs for use by other modules
 * (Secrets Manager, EC2 EBS encryption, CloudWatch Logs)
 *
 * Note: These outputs work regardless of whether keys are
 * newly created or reused from existing resources.
 */

# -----------------------------------------------------------------------------
# Symmetric KMS Key Outputs (N. Virginia)
# -----------------------------------------------------------------------------
output "nvirginia_key_arn" {
  description = "ARN of the symmetric KMS key in N. Virginia"
  value       = local.nvirginia_key_arn
}

output "nvirginia_key_id" {
  description = "ID of the symmetric KMS key in N. Virginia"
  value       = local.nvirginia_key_id
}

output "nvirginia_key_alias" {
  description = "Alias of the symmetric KMS key in N. Virginia"
  value       = "alias/symmetric_kms-${var.name_suffix_nvirginia}"
}

# -----------------------------------------------------------------------------
# London KMS Key Outputs
# -----------------------------------------------------------------------------
output "london_key_arn" {
  description = "ARN of the KMS replica key in London"
  value       = local.london_key_arn
}

output "london_key_id" {
  description = "ID of the KMS replica key in London"
  value       = local.london_key_id
}

output "london_key_alias" {
  description = "Alias of the KMS replica key in London"
  value       = "alias/replica_symmetric_kms-${var.name_suffix_london}"
}

# -----------------------------------------------------------------------------
# Key Reuse Status (for debugging/visibility)
# -----------------------------------------------------------------------------
output "nvirginia_key_reused" {
  description = "True if an existing N. Virginia key was reused"
  value       = local.nvirginia_key_exists
}

output "london_key_reused" {
  description = "True if an existing London key was reused"
  value       = local.london_key_exists
}
