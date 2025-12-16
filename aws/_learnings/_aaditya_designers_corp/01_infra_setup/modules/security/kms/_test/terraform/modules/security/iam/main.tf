/**
 * IAM User for KMS Decrypt-Only Access
 *
 * Creates an IAM user with minimal permissions:
 *   - kms:Decrypt - Decrypt data using the specified KMS key
 *
 * This follows the principle of least privilege.
 * The user can ONLY decrypt, not encrypt, delete, or manage keys.
 */

# -----------------------------------------------------------------------------
# IAM User for Backend Application
# -----------------------------------------------------------------------------
resource "aws_iam_user" "kms_decrypt" {
  name = "kms-decrypt-user-${var.name_suffix}"
  path = "/service-accounts/"

  tags = merge(var.tags, {
    Name    = "kms-decrypt-user-${var.name_suffix}"
    Purpose = "Backend application KMS decrypt access"
  })
}

# -----------------------------------------------------------------------------
# IAM Policy - KMS Decrypt Only
# -----------------------------------------------------------------------------
resource "aws_iam_policy" "kms_decrypt" {
  name        = "kms-decrypt-policy-${var.name_suffix}"
  description = "Allows KMS decrypt operations on specific key"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowKMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = var.kms_key_arn
      }
    ]
  })

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Attach Policy to User
# -----------------------------------------------------------------------------
resource "aws_iam_user_policy_attachment" "kms_decrypt" {
  user       = aws_iam_user.kms_decrypt.name
  policy_arn = aws_iam_policy.kms_decrypt.arn
}

# -----------------------------------------------------------------------------
# Access Keys for User
# -----------------------------------------------------------------------------
resource "aws_iam_access_key" "kms_decrypt" {
  user = aws_iam_user.kms_decrypt.name
}
