/**
 * KMS and IAM Setup for Use-Case 1: 3rd Party WITHOUT AWS Account
 *
 * Uses modules to create:
 *   1. KMS Asymmetric Key (RSA-4096) for encryption/decryption
 *   2. IAM User with decrypt-only permissions
 *
 * Flow:
 *   1. 3rd party gets public key via API
 *   2. 3rd party encrypts PII data with public key (RSA-OAEP)
 *   3. Company backend decrypts using KMS (private key never leaves KMS)
 */

# -----------------------------------------------------------------------------
# KMS Module - Asymmetric Key
# NOTE: Reuses existing KMS key if found (detected via data sources)
# -----------------------------------------------------------------------------
module "kms" {
  source = "./modules/security/kms"

  providers = {
    aws = aws.nvirginia
  }

  name_suffix          = local.name_suffix
  key_deletion_window  = var.key_deletion_window
  account_id           = data.aws_caller_identity.current.account_id
  profile              = var.profile
  region               = local.regions_cfg[local.REGION_N_VIRGINIA]
  tags                 = local.tags_common
}

# -----------------------------------------------------------------------------
# IAM Module - KMS Decrypt User
# -----------------------------------------------------------------------------
module "iam" {
  source = "./modules/security/iam"

  providers = {
    aws = aws.nvirginia
  }

  name_suffix = local.name_suffix
  kms_key_arn = module.kms.key_arn
  tags        = local.tags_common
}
