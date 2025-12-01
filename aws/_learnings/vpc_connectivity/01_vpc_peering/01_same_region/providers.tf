/**
 * VPC Peering - Same Region
 *
 * AWS Provider configuration for N. Virginia region.
 * This chapter demonstrates VPC peering between vpc_a and vpc_b
 * within the same region (us-east-1).
 */

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      environment = var.environment
      managed_by  = "terraform"
      project     = "vpc-peering-learning"
    }
  }
}
