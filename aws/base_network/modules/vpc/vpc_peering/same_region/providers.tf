/**
 * AWS Provider Configuration
 *
 * Sets up AWS provider for N. Virginia region (us-east-1).
 * Uses the same pattern as base_network for consistency.
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
  region  = "us-east-1"
  profile = var.profile
}
