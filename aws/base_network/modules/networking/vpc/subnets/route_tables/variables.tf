/**
 * Input Variables for Route Tables Module
 *
 * @var vpcs            - VPC configurations from networking.json
 *                        Contains subnet definitions with tier (public/private)
 *
 * @var vpc_ids         - Map of VPC names to their AWS resource IDs
 *                        Example: { "vpc_a" = "vpc-abc123" }
 *
 * @var igw_ids         - Map of VPC names to Internet Gateway IDs
 *                        Used by public route tables for direct internet access
 *                        Also passed to private module for NAT Gateway dependency
 *                        Example: { "vpc_a" = "igw-xyz789" }
 *
 * @var igw_names       - Map of VPC names to Internet Gateway Name tags
 *                        Used by private module for NAT Gateway output display
 *                        Example: { "vpc_a" = "igw-vpc_a-nvirginia-dev-terraform" }
 *
 * @var subnet_ids      - Map of subnet keys to their AWS resource IDs
 *                        Key format: "{vpc_name}/{tier}_zone_{zone}"
 *                        Example: { "vpc_a/public_zone_a" = "subnet-111222" }
 *
 * @var common_tags     - Tags applied to all route table resources
 *                        Example: { environment = "dev", managed_by = "terraform" }
 *
 * @var name_suffix     - Standard suffix for resource naming
 *                        Format: {region}-{environment}-{managed_by}
 *                        Example: "nvirginia-dev-terraform"
 */
variable "vpcs"        { type = map(any) }
variable "vpc_ids"     { type = map(string) }
variable "igw_ids"     { type = map(string) }
variable "igw_names"   { type = map(string) }
variable "subnet_ids"  { type = map(string) }
variable "common_tags" { type = map(string) }
variable "name_suffix" { type = string }
