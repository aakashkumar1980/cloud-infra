/**
 * A map of VPC configurations to create.
 * Each key is a unique identifier for the VPC, and the value is a map of VPC attributes.
 */
variable "vpcs"        { type = map(any) }

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
 * The common tags to apply to all resources.
 * Example: { "Environment" = "Production", "Owner" = "DevOps" }
 */
variable "common_tags" { type = map(string) }

/**
 * The AWS region where resources will be created.
 * Example: "us-west-2"
 */
variable "region"      { type = string }