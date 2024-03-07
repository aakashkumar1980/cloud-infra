### profile available in ~/.aws/config & ~/.aws/credentials file for both "default" & "secondary" profiles.
provider "aws" {
  region = "us-east-1"
  alias  = "region_nvirginia"

  profile = "default"
}
provider "aws" {
  region = "eu-west-2"
  alias  = "region_london"

  profile = "secondary"
}

/** PrivateLearningV2 **/
provider "aws" {
  region = "us-west-1"
  alias  = "region_ncalifornia"

  profile = "teritary"
}
