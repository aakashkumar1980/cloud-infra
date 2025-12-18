/**
 * Terraform and Provider Configuration for KMS _test
 */
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# N. Virginia provider (primary region for KMS asymmetric key)
provider "aws" {
  alias   = "nvirginia"
  region  = local.regions_cfg[local.REGION_N_VIRGINIA]
  profile = var.profile

  default_tags {
    tags = local.tags_common
  }
}
