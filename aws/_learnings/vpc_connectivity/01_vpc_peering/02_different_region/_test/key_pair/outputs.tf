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

output "private_key_pem" {
  value       = var.public_key_openssh == null ? tls_private_key.ssh_key[0].private_key_pem : null
  description = "Private key in PEM format (only available when key is generated, not imported)"
  sensitive   = true
}

output "public_key_openssh" {
  value       = var.public_key_openssh != null ? var.public_key_openssh : tls_private_key.ssh_key[0].public_key_openssh
  description = "Public key in OpenSSH format"
}
