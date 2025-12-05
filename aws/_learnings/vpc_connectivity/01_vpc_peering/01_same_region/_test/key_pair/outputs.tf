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
  value       = tls_private_key.ssh_key.private_key_pem
  description = "Private key in PEM format (save to file for SSH access)"
  sensitive   = true
}

output "public_key_openssh" {
  value       = tls_private_key.ssh_key.public_key_openssh
  description = "Public key in OpenSSH format"
}
