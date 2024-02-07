### profile available in ~/.aws/credentials file
provider "aws" {
  region = "us-east-1"
  alias  = "region_nvirginia"

  profile = "privatelearningv2"
}
provider "aws" {
  region = "eu-west-2"
  alias  = "region_london"

  profile = "privatelearningv2"
}


provider "aws" {
  region = "ap-south-1"
  alias  = "region_mumbai"

  profile = "privatelearningv2"
}