/**
 * Input Variables for Private Route Tables
 *
 * @var vpcs               - VPC configurations containing subnet definitions
 *                           Used to identify which subnets are private (tier = "private")
 *
 * @var vpc_ids            - Map of VPC names to their AWS resource IDs
 *                           Route tables must be created within a specific VPC
 *
 * @var public_subnet_ids  - Map of public subnet keys to their AWS resource IDs
 *                           Used by NAT Gateway module to place NAT GW in public subnet
 *
 * @var private_subnet_ids - Map of private subnet keys to their AWS resource IDs
 *                           Used to associate route tables with private subnets
 *
 * @var igw_ids            - Map of VPC names to Internet Gateway IDs
 *                           NAT Gateway depends on IGW being created first
 *
 * @var igw_names          - Map of VPC names to Internet Gateway Name tags
 *                           Used for output display showing NAT GW -> IGW relationship
 *
 * @var tags_common        - Tags applied to all route table resources
 *                           Includes environment, managed_by, and other standard tags
 *
 * @var name_suffix        - Standard suffix for resource naming
 *                           Format: {region}-{environment}-{managed_by}
 *                           Example: "nvirginia-dev-terraform"
 */
variable "vpcs"               { type = map(any) }
variable "vpc_ids"            { type = map(string) }
variable "public_subnet_ids"  { type = map(string) }
variable "private_subnet_ids" { type = map(string) }
variable "igw_ids"            { type = map(string) }
variable "igw_names"          { type = map(string) }
variable "tags_common"        { type = map(string) }
variable "name_suffix"        { type = string }
