/**
 * A map of VPC configurations to create.
 * Each key is a unique identifier for the VPC, and the value is a map of VPC attributes.
 */
variable "vpcs" { type = map(any) }

/**
 * A map of VPC IDs where route tables will be created.
 * Each key is a unique identifier for the VPC, and the value is the corresponding VPC ID.
 */
variable "vpc_ids" { type = map(string) }

/**
 * A map of NAT Gateway IDs for routing internet-bound traffic.
 * Each key is a VPC name, and the value is the corresponding NAT Gateway ID.
 */
variable "nat_gateway_ids" { type = map(string) }

/**
 * A map of subnet IDs for route table associations.
 * Each key is the subnet identifier (e.g., "vpc_c/private_zone_b"), and the value is the subnet ID.
 */
variable "subnet_ids" { type = map(string) }

/**
 * The common tags to apply to all resources.
 * Example: { "Environment" = "Production", "Owner" = "DevOps" }
 */
variable "common_tags" { type = map(string) }

/**
 * The AWS region where resources will be created.
 * Example: "us-west-2"
 */
variable "region" { type = string }
