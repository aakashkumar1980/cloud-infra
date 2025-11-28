/**
 * AWS Providers Configuration
 *
 * Sets up two AWS providers to deploy resources in different regions:
 *   - nvirginia: US East (N. Virginia) - us-east-1
 *   - london: EU (London) - eu-west-2
 *
 * The profile variable selects which AWS credentials to use (dev, stage, prod).
 *
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

provider "aws" {
  alias   = "nvirginia"
  region  = local.regions_cfg["nvirginia"]
  profile = var.profile
}

provider "aws" {
  alias   = "london"
  region  = local.regions_cfg["london"]
  profile = var.profile
}
