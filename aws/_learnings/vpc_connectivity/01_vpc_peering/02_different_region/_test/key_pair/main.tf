/**
 * Key Pair Module - Cross-Region Support
 *
 * Creates an RSA key pair for SSH access to EC2 instances.
 * Can either generate a new key pair or use an existing public key.
 *
 * Cross-Region Usage:
 *   - First call: Generate new key pair (public_key_openssh = null)
 *   - Second call: Use existing public key to register in another region
 *
 * Usage:
 *   After terraform apply, save the private key:
 *   terraform output -raw private_key_pem > ~/.ssh/vpc-peering-test.pem
 *   chmod 400 ~/.ssh/vpc-peering-test.pem
 */

/**
 * Generate RSA Private Key (only if not using existing public key)
 *
 * Creates a 4096-bit RSA key pair locally using the TLS provider.
 */
resource "tls_private_key" "ssh_key" {
  count = var.public_key_openssh == null ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

/**
 * AWS Key Pair
 *
 * Registers the public key with AWS for EC2 instance access.
 * Uses either the generated public key or an existing one (for cross-region).
 */
resource "aws_key_pair" "generated_key" {
  key_name   = "test_key-${var.name_suffix}"
  public_key = var.public_key_openssh != null ? var.public_key_openssh : tls_private_key.ssh_key[0].public_key_openssh

  tags = {
    Name = "test_key-${var.name_suffix}"
  }
}
