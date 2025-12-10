/**
 * Main Infrastructure Setup
 *
 * Aaditya Designers Corp - Enterprise Infrastructure
 *
 * This configuration sets up:
 *   - Phase 1: Security Foundation (KMS, Secrets Manager, IAM, Security Groups)
 *   - Phase 2: AD DS + AD CS on Windows EC2 (N. Virginia)
 *   - Phase 3: Keycloak + Apache Syncope (London)
 *   - Phase 4: GitLab CE + Wiki.js (London)
 *   - Phase 5: Monitoring & Backup
 *
 * Multi-Region Setup:
 *   - N. Virginia (us-east-1): Microsoft AD infrastructure
 *   - London (eu-west-2): Application servers
 */

# =============================================================================
# PHASE 1: SECURITY FOUNDATION
# =============================================================================

# -----------------------------------------------------------------------------
# 1a. KMS - Encryption Keys
# -----------------------------------------------------------------------------
module "kms" {
  source = "./modules/security/kms"

  providers = {
    aws.nvirginia = aws.nvirginia
    aws.london    = aws.london
  }

  nvirginia_region = local.regions_cfg[local.REGION_N_VIRGINIA]
  london_region    = local.regions_cfg[local.REGION_LONDON]
  tags_common      = local.tags_common
}

# -----------------------------------------------------------------------------
# 1b. Secrets Manager - Secure Credential Storage
# -----------------------------------------------------------------------------
module "secrets_manager" {
  source = "./modules/security/secrets_manager"

  providers = {
    aws.nvirginia = aws.nvirginia
  }

  kms_key_arn = module.kms.nvirginia_key_arn
  tags_common = local.tags_common
}
