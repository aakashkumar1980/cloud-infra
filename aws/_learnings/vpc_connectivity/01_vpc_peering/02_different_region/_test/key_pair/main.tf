/**
 * Key Pair Module
 *
 * Creates an RSA key pair for SSH access to EC2 instances.
 * The private key is generated locally and the public key is
 * registered with AWS as a key pair.
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
 */
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

/**
 * AWS Key Pair
 *
 * Registers the public key with AWS for EC2 instance access.
 */
resource "aws_key_pair" "generated_key" {
  key_name   = "test_key-${var.name_suffix}"
  public_key = tls_private_key.ssh_key.public_key_openssh

  tags = {
    Name = "test_key-${var.name_suffix}"
  }
}
