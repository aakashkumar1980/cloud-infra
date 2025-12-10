/**
 * Secrets Manager Module - Provider Configuration
 *
 * Secrets are stored centrally in N. Virginia region.
 * EC2 instances in London can still access them via cross-region API calls.
 */

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.nvirginia]
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
