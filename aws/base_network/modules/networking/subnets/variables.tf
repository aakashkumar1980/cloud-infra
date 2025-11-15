/**
 * The AWS region where resources will be created.
 * Example: "us-west-2"
 */
variable "region"          { type = string }

/**
 * A map of VPC configurations to create.
 * Each key is a unique identifier for the VPC, and the value is a map of VPC attributes.
 */
variable "vpcs"            { type = map(any) }

/**
 * A map of VPC IDs where subnets will be created.
 * Each key is a unique identifier for the VPC, and the value is the corresponding VPC ID.
 */
variable "vpc_ids"         { type = map(string) }

/**
 * A map of subnet configurations to create.
 * Each key is a unique identifier for the subnet, and the value is a map of subnet attributes.
 * Example: ["us-west-2a", "us-west-2b", "us-west-2c"]
 */
variable "az_names"        { type = list(string) }

/**
 * A map of subnet configurations to create.
 * Each key is a unique identifier for the subnet, and the value is a map of subnet attributes.
 * Example: { "a" = 0, "b" = 1, "c" = 2 }
 */
variable "az_letter_to_ix" { type = map(number) }

/**
 * The common tags to apply to all resources.
 * Example: { "Environment" = "Production", "Owner" = "DevOps" ... }
 */
variable "common_tags"     { type = map(string) }
