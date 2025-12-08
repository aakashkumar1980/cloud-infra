/**
 * AWS Provider Configuration - Cross-Region
 *
 * Sets up AWS providers for both N. Virginia (us-east-1) and London (eu-west-2)
 * regions to enable cross-region VPC peering.
 *
 * Provider Aliases:
 *   - aws.nvirginia: N. Virginia (us-east-1) - Requester VPC
 *   - aws.london:    London (eu-west-2)      - Accepter VPC
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

/** Default provider - N. Virginia (Requester) */
provider "aws" {
  alias   = "nvirginia"
  region  = "us-east-1"
  profile = var.profile
}

/** London provider (Accepter) */
provider "aws" {
  alias   = "london"
  region  = "eu-west-2"
  profile = var.profile
}
