/**
 * AWS Providers Configuration
 *
 * Sets up AWS providers for multi-region deployment.
 * The profile variable selects which AWS credentials to use (dev, stage, prod).
 *
 * TERRAFORM LIMITATION:
 *   Provider blocks cannot use for_each or dynamic expressions.
 *   Each region requires its own provider block with a static alias.
 *   Region codes are referenced from local.regions for consistency.
 *
 * To add a new region:
 *   1. Add to local.regions in locals.tf
 *   2. Add provider block below (copy existing pattern)
 *   3. Add data source in data.tf
 *   4. Add module block in main.tf
 */
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# N. Virginia Region (us-east-1)
# ─────────────────────────────────────────────────────────────────────────────
provider "aws" {
  alias   = "nvirginia"
  region  = local.regions["nvirginia"]
  profile = var.profile
}

# ─────────────────────────────────────────────────────────────────────────────
# London Region (eu-west-2)
# ─────────────────────────────────────────────────────────────────────────────
provider "aws" {
  alias   = "london"
  region  = local.regions["london"]
  profile = var.profile
}
