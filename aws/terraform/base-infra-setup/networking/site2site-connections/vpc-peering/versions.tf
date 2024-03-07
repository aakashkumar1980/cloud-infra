terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 3.0"
      configuration_aliases = [aws.rgn_nvg, aws.rgn_ldn, aws.rgn_ncf]
    }
  }
}
