### profile available in ~/.aws/credentials file
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
