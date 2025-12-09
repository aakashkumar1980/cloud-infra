/**
 * Key Pair Module
 *
 * Creates an RSA key pair for SSH access to EC2 instances.
 * The private key is generated locally and the public key is
 * registered with AWS as a key pair.
 *
 * Supports two modes:
 *   1. Generate new key: When public_key_openssh is null
 *   2. Import existing key: When public_key_openssh is provided
 *      (useful for sharing same key across regions)
 *
 * Usage:
 *   After terraform apply, save the private key:
 *   terraform output -raw private_key_pem > ~/.ssh/vpc-peering-test.pem
 *   chmod 400 ~/.ssh/vpc-peering-test.pem
 */

/**
 * Generate RSA Private Key
 *
 * Creates a 4096-bit RSA key pair locally using the TLS provider.
 * Only created when no existing public key is provided.
 */
resource "tls_private_key" "ssh_key" {
  count     = var.public_key_openssh == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

/**
 * AWS Key Pair
 *
 * Registers the public key with AWS for EC2 instance access.
 * Uses either the generated key or an imported existing key.
 */
resource "aws_key_pair" "generated_key" {
  key_name   = "test_key-${var.name_suffix}"
  public_key = var.public_key_openssh != null ? var.public_key_openssh : tls_private_key.ssh_key[0].public_key_openssh

  tags = {
    Name = "test_key-${var.name_suffix}"
  }
}
