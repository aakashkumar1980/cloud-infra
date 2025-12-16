/**
 * IAM Module Outputs
 *
 * IMPORTANT: The secret_access_key is sensitive.
 * Store it securely (AWS Secrets Manager recommended for production).
 */

output "user_name" {
  description = "IAM User name"
  value       = aws_iam_user.kms_decrypt.name
}

output "user_arn" {
  description = "IAM User ARN"
  value       = aws_iam_user.kms_decrypt.arn
}

output "access_key_id" {
  description = "AWS Access Key ID for the KMS decrypt user"
  value       = aws_iam_access_key.kms_decrypt.id
}

output "secret_access_key" {
  description = "AWS Secret Access Key for the KMS decrypt user (sensitive)"
  value       = aws_iam_access_key.kms_decrypt.secret
  sensitive   = true
}

output "policy_arn" {
  description = "ARN of the KMS decrypt policy"
  value       = aws_iam_policy.kms_decrypt.arn
}
