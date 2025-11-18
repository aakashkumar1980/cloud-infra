/**
 * A map of VPC configurations to create.
 * Each key is a unique identifier for the VPC, and the value is a map of VPC attributes.
 */
variable "vpcs"        { type = map(any) }

/**
 * A map of VPC IDs where Internet Gateways will be attached.
 * Each key is a unique identifier for the VPC, and the value is the corresponding VPC ID.
 */
variable "vpc_ids"     { type = map(string) }

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
