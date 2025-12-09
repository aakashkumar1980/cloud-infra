/**
 * Key Pair Module - Outputs
 */

output "key_name" {
  value       = aws_key_pair.generated_key.key_name
  description = "Name of the created AWS key pair"
}

output "key_pair_id" {
  value       = aws_key_pair.generated_key.key_pair_id
  description = "ID of the created AWS key pair"
}
