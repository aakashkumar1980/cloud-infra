/**
 * KMS Asymmetric Key for Use-Case 1: 3rd Party WITHOUT AWS Account
 *
 * Creates an RSA-4096 asymmetric key pair:
 *   - Public Key:  Exported and shared with 3rd party clients
 *   - Private Key: Never leaves KMS, used for decryption
 *
 * Set var.create_resources = false to skip creation and use existing key via data source.
 */

# -----------------------------------------------------------------------------
# Data source to lookup existing alias (only when not creating)
# -----------------------------------------------------------------------------
data "aws_kms_alias" "existing" {
  count = var.create_resources ? 0 : 1
  name  = "alias/test_asymmetric_kms-${var.name_suffix}"
}

# -----------------------------------------------------------------------------
# Asymmetric KMS Key (RSA-4096) for 3rd Party Encryption
# -----------------------------------------------------------------------------
resource "aws_kms_key" "asymmetric" {
  count                    = var.create_resources ? 1 : 0
  description              = "Test Asymmetric RSA key for 3rd party encryption (Use-Case 1)"
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
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Public Key Export"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action = [
          "kms:GetPublicKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name    = "test_asymmetric_kms-${var.name_suffix}"
    UseCase = "third-party-no-aws"
    KeyType = "RSA_4096"
    Purpose = "3rd party encryption without AWS account"
  })
}

# -----------------------------------------------------------------------------
# KMS Alias
# -----------------------------------------------------------------------------
resource "aws_kms_alias" "asymmetric" {
  count         = var.create_resources ? 1 : 0
  name          = "alias/test_asymmetric_kms-${var.name_suffix}"
  target_key_id = aws_kms_key.asymmetric[0].key_id
}
