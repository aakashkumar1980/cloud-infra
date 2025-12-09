/**
 * Key Pair Module
 *
 * Registers an SSH public key with AWS for EC2 instance access.
 * The public key must be provided - this module only handles
 * AWS key pair registration.
 *
 * Key generation should be done at the root module level to ensure
 * the same key can be shared across multiple regions.
 */

/**
 * AWS Key Pair
 *
 * Registers the public key with AWS for EC2 instance access.
 */
resource "aws_key_pair" "generated_key" {
  key_name   = "test_key-${var.name_suffix}"
  public_key = var.public_key_openssh

  tags = {
    Name = "test_key-${var.name_suffix}"
  }
}
