/**
 * A map of VPC configurations to create.
 * Each key is a unique identifier for the VPC, and the value is a map of VPC attributes.
 */
variable "vpcs" { type = map(any) }

/**
 * A map of VPC IDs where NAT Gateways will be created.
 * Each key is a unique identifier for the VPC, and the value is the corresponding VPC ID.
 */
variable "vpc_ids" { type = map(string) }

/**
 * A map of subnet IDs where NAT Gateways will be placed.
 * Each key is the subnet identifier (e.g., "vpc_a/public_zone_a"), and the value is the subnet ID.
 * NAT Gateways must be placed in public subnets.
 */
variable "subnet_ids" { type = map(string) }

/**
 * A map of Internet Gateway IDs for dependency management.
 * Each key is a VPC name, and the value is the corresponding Internet Gateway ID.
 * NAT Gateways require Internet Gateways to exist for internet connectivity.
 */
variable "igw_ids" { type = map(string) }

/**
 * A map of Internet Gateway names for reference in outputs.
 * Each key is a VPC name, and the value is the corresponding Internet Gateway name.
 */
variable "igw_names" { type = map(string) }

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
