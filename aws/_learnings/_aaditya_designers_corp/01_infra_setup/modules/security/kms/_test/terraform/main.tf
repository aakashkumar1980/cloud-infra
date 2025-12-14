/**
 * KMS Asymmetric Key for Use-Case 1: 3rd Party WITHOUT AWS Account
 *
 * Creates an RSA-4096 asymmetric key pair:
 *   - Public Key:  Exported and shared with 3rd party clients
 *   - Private Key: Never leaves KMS, used for decryption
 *
 * Flow:
 *   1. 3rd party gets public key via API
 *   2. 3rd party encrypts DEK with public key (RSA)
 *   3. 3rd party encrypts data with DEK (AES-GCM)
 *   4. Company backend decrypts DEK using KMS (private key)
 *   5. Company backend decrypts data with DEK
 */

# -----------------------------------------------------------------------------
# Asymmetric KMS Key (RSA-4096) for 3rd Party Encryption
# -----------------------------------------------------------------------------
resource "aws_kms_key" "asymmetric" {
  provider = aws.nvirginia

  description              = "Asymmetric RSA key for 3rd party encryption (Use-Case 1)"
  deletion_window_in_days  = var.key_deletion_window
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "RSA_4096"

  # Note: Asymmetric keys do NOT support automatic key rotation
  # You must manually rotate by creating a new key

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Public Key Export"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "kms:GetPublicKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.tags_common, {
    Name     = "kms-asymmetric-${local.name_suffix}"
    UseCase  = "third-party-no-aws"
    KeyType  = "RSA_4096"
    Purpose  = "3rd party encryption without AWS account"
  })
}

resource "aws_kms_alias" "asymmetric" {
  provider = aws.nvirginia

  name          = "alias/aaditya-asymmetric-${var.profile}"
  target_key_id = aws_kms_key.asymmetric.key_id
}
