/**
 * The AWS region where resources will be created.
 * Example: "us-west-2"
 */
variable "region"      { type = string }

/**
 * A map of VPC configurations to create.
 * Each key is a unique identifier for the VPC, and the value is a map of VPC attributes.
 */
variable "vpcs"        { type = map(any) }

/**
 * The common tags to apply to all resources.
 * Example: { "Environment" = "Production", "Owner" = "DevOps" }
 */
variable "common_tags" { type = map(string) }


