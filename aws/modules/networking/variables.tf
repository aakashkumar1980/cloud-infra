/**
 * AWS Region
 * Example: "us-east-1"
 */
variable "region" { type = string }

/**
 * VPC Definitions
  Example:
  {
    vpc_a = {
      cidr = "10.0.0.0/24"
      subnets = [
        { id="1", name="public-a",  tier="public",  cidr="10.0.0.32/27", az="a" },
        { id="2", name="private-a", tier="private", cidr="10.0.0.96/27", az="a" }
      ]
    }
  }
 */
variable "vpcs" { type = map(any) }

/**
 * Availability Zone Names
 * Example: [ "us-east-1a", "us-east-1b", "us-east-1c" ]
 */
variable "az_names" { type = list(string) }

/**
 * AZ Letter to Index Mapping
 * Example: { a=0, b=1, c=2 }
 */
variable "az_letter_to_ix" { type = map(number) }

/**
 * Common Tags
 * Example: { environment="prod", project="myapp" ... }
 */
variable "common_tags" { type = map(string) }
