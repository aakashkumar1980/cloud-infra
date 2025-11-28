# Two AWS providers for multi-region deployment:
#   - nvirginia: US East (N. Virginia) - us-east-1
#   - london: EU (London) - eu-west-2
#
# Usage: terraform plan -var="profile=dev"

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
