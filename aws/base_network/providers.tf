/**
 * Providers
 *
 * - Two AWS provider aliases for our two regions.
 *  alias "nvirginia" → AWS region us-east-1
 *  alias "london"    → AWS region eu-west-2
 *
 * - The AWS CLI profile is injected via var.profile (e.g., "dev", "qa", "prod").
 *
 * Sample:
 *   terraform plan -var="profile=dev"
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
  region  = "us-east-1"
  profile = var.profile
}

provider "aws" {
  alias   = "london"
  region  = "eu-west-2"
  profile = var.profile
}
