/**
 * KMS Module - Key Management Service
 *
 * Creates a Customer Managed Key (CMK) for encrypting:
 *   - EBS volumes (AD server, App servers)
 *   - Secrets Manager secrets
 *   - S3 backups
 *   - CloudWatch logs
 *
 * Cost: ~$1/month per key
 *
 * Key Features:
 *   - Automatic yearly key rotation
 *   - Multi-region keys for cross-region encryption
 *   - Least privilege key policy
 *   - Key reuse: Looks up existing keys by alias before creating new ones
 *   - Protection: prevent_destroy lifecycle prevents accidental deletion
 */

# -----------------------------------------------------------------------------
# Symmetric KMS Key for N. Virginia Region (AD Server)
# Only created if existing key is not found
# -----------------------------------------------------------------------------
resource "aws_kms_key" "kms_nvirginia" {
  provider = aws.nvirginia

  # Only create if existing key not found
  count = local.nvirginia_key_exists ? 0 : 1

  description             = "CMK for Aaditya Designers Corp - N. Virginia (AD, EBS, Secrets)"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  multi_region            = true

  # Key policy - who can use this key
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
        Sid    = "Allow EC2 Service to use key for EBS encryption"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs to use key"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.nvirginia_region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.nvirginia_region}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "symmetric_kms-${var.name_suffix_nvirginia}"
  }

  # Prevent accidental deletion of KMS keys
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "kms_nvirginia" {
  provider = aws.nvirginia

  # Only create if we created a new key
  count = local.nvirginia_key_exists ? 0 : 1

  name          = "alias/symmetric_kms-${var.name_suffix_nvirginia}"
  target_key_id = aws_kms_key.kms_nvirginia[0].key_id
}

# -----------------------------------------------------------------------------
# KMS Key Replica for London Region (App Servers)
# Only created if existing key is not found
# -----------------------------------------------------------------------------
resource "aws_kms_replica_key" "kms_london" {
  provider = aws.london

  # Only create if existing key not found AND primary key exists
  count = local.london_key_exists ? 0 : (local.nvirginia_key_arn != null ? 1 : 0)

  description             = "CMK Replica for Aaditya Designers Corp - London (Apps, EBS, Secrets)"
  primary_key_arn         = local.nvirginia_key_arn
  deletion_window_in_days = 7

  # Key policy for London region
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
        Sid    = "Allow EC2 Service to use key for EBS encryption"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs to use key"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.london_region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.london_region}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "replica_symmetric_kms-${var.name_suffix_london}"
  }

  # Prevent accidental deletion of KMS keys
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "kms_london" {
  provider = aws.london

  # Only create if we created a new replica key
  count = local.london_key_exists ? 0 : (local.nvirginia_key_arn != null ? 1 : 0)

  name          = "alias/replica_symmetric_kms-${var.name_suffix_london}"
  target_key_id = aws_kms_replica_key.kms_london[0].key_id
}
