/**
 * KMS Asymmetric Key for Use-Case 1: 3rd Party WITHOUT AWS Account
 *
 * Creates an RSA-4096 asymmetric key pair:
 *   - Public Key:  Exported and shared with 3rd party clients
 *   - Private Key: Never leaves KMS, used for decryption
 *
 * NOTE: If a KMS key with the same alias already exists in AWS:
 *   - The existing key will be reused (not recreated)
 *   - The key is protected from accidental deletion via lifecycle prevent_destroy
 */

# -----------------------------------------------------------------------------
# Asymmetric KMS Key (RSA-4096) for 3rd Party Encryption
# Only created if the key doesn't already exist in AWS
# -----------------------------------------------------------------------------
resource "aws_kms_key" "asymmetric" {
  count = local.kms_key_exists ? 0 : 1

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
    Name     = "test_asymmetric_kms-${var.name_suffix}"
    UseCase  = "third-party-no-aws"
    KeyType  = "RSA_4096"
    Purpose  = "3rd party encryption without AWS account"
  })

  # Prevent accidental deletion - KMS keys have mandatory 7-30 day waiting period
  lifecycle {
    prevent_destroy = true
  }
}

# -----------------------------------------------------------------------------
# KMS Alias - Only created if the key doesn't already exist
# -----------------------------------------------------------------------------
resource "aws_kms_alias" "asymmetric" {
  count = local.kms_key_exists ? 0 : 1

  name          = "alias/test_asymmetric_kms-${var.name_suffix}"
  target_key_id = aws_kms_key.asymmetric[0].key_id
}

# -----------------------------------------------------------------------------
# Local values for output references
# -----------------------------------------------------------------------------
locals {
  # Use existing key if found, otherwise use newly created key
  effective_key_id    = local.kms_key_exists ? local.existing_key_id : aws_kms_key.asymmetric[0].key_id
  effective_key_arn   = local.kms_key_exists ? data.aws_kms_key.existing[0].arn : aws_kms_key.asymmetric[0].arn
  effective_key_alias = "alias/test_asymmetric_kms-${var.name_suffix}"
}
