/**
 * Input Variables for Route Tables Module
 *
 * @var vpcs               - VPC configurations from networking.json
 *                           Contains subnet definitions with tier (public/private)
 *
 * @var vpc_ids            - Map of VPC names to their AWS resource IDs
 *                           Example: { "vpc_a" = "vpc-abc123" }
 *
 * @var igw_ids            - Map of VPC names to Internet Gateway IDs
 *                           Used by public route tables for direct internet access
 *                           Also passed to private module for NAT Gateway dependency
 *                           Example: { "vpc_a" = "igw-xyz789" }
 *
 * @var igw_names          - Map of VPC names to Internet Gateway Name tags
 *                           Used by private module for NAT Gateway output display
 *                           Example: { "vpc_a" = "igw-vpc_a-nvirginia-dev-terraform" }
 *
 * @var public_subnet_ids  - Map of public subnet keys to their AWS resource IDs
 *                           Used by public route tables and NAT Gateway placement
 *                           Key format: "{vpc_name}/public_zone_{zone}"
 *                           Example: { "vpc_a/public_zone_a" = "subnet-111222" }
 *
 * @var private_subnet_ids - Map of private subnet keys to their AWS resource IDs
 *                           Used by private route tables for subnet associations
 *                           Key format: "{vpc_name}/private_zone_{zone}"
 *                           Example: { "vpc_a/private_zone_a" = "subnet-333444" }
 *
 * @var tags_common        - Tags applied to all route table resources
 *                           Example: { environment = "dev", managed_by = "terraform" }
 *
 * @var name_suffix        - Standard suffix for resource naming
 *                           Format: {region}-{environment}-{managed_by}
 *                           Example: "nvirginia-dev-terraform"
 */
variable "vpcs"               { type = map(any) }
variable "vpc_ids"            { type = map(string) }
variable "igw_ids"            { type = map(string) }
variable "igw_names"          { type = map(string) }
variable "public_subnet_ids"  { type = map(string) }
variable "private_subnet_ids" { type = map(string) }
variable "tags_common"        { type = map(string) }
variable "name_suffix"        { type = string }
