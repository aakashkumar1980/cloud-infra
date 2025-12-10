/**
 * KMS Module - Provider Configuration
 *
 * This module requires two AWS providers to be passed in:
 *   - aws.nvirginia: For the primary KMS key
 *   - aws.london: For the replica KMS key
 */

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.nvirginia, aws.london]
    }
  }
}
