/**
 * A map of VPC configurations to create.
 * Each key is a unique identifier for the VPC, and the value is a map of VPC attributes.
 */
variable "vpcs"            { type = map(any) }

/**
 * A map of VPC IDs where route tables will be created.
 * Each key is a unique identifier for the VPC, and the value is the corresponding VPC ID.
 */
variable "vpc_ids"         { type = map(string) }

/**
 * A map of Internet Gateway IDs for routing internet traffic.
 * Each key is a unique identifier for the VPC, and the value is the corresponding IGW ID.
 */
variable "igw_ids"         { type = map(string) }

/**
 * A map of subnet IDs for route table associations.
 * Each key is in format "vpc_name/subnet_id", and the value is the corresponding subnet ID.
 */
variable "subnet_ids"      { type = map(string) }

/**
 * The common tags to apply to all resources.
 * Example: { "Environment" = "Production", "Owner" = "DevOps" }
 */
variable "common_tags"     { type = map(string) }

/**
 * The AWS region where resources will be created.
 * Example: "us-west-2"
 */
variable "region"          { type = string }
