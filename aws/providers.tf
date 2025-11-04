/**
 * Providers and region aliases.
 * We keep both regions open through provider aliases,
 * which is the standard way to target multiple regions in a single state.
 */
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

/** Default (not used directly), but handy if a child module expects a default aws provider */
provider "aws" {
  region = "us-east-1"
}

/** North Virginia */
provider "aws" {
  alias  = "nvirginia"
  region = "us-east-1"
}

/** London */
provider "aws" {
  alias  = "london"
  region = "eu-west-2"
}
