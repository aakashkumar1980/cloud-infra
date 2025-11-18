/**
 * VPC Definitions
  Example:
  {
    vpc_a = {
      cidr = "10.0.0.0/24"
      subnets = [
        { tier="public",  cidr="10.0.0.32/27", az="a" },
        { tier="private", cidr="10.0.0.96/27", az="a" }
      ]
    }
  }
 */
variable "vpcs" { type = map(any) }

/**
 * Availability Zone Names
 * Example: ["a", "b", "c"]
 */
variable "az_names" { type = list(string) }

/**
 * Availability Zone Letter to Index Mapping
 * Example: { a=0, b=1, c=2 }
 */
variable "az_letter_to_ix" { type = map(number) }

/**
 * Common Tags
 * Example: { environment="prod", project="myapp" ... }
 */
variable "common_tags" { type = map(string) }

/**
 * AWS Region
 * Example: "us-east-1"
 */
variable "region" { type = string }