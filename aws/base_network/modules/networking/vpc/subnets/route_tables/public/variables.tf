/**
 * Input Variables for Public Route Tables
 *
 * @var vpcs        - VPC configurations containing subnet definitions
 *                    Used to identify which subnets are public (tier = "public")
 *
 * @var vpc_ids     - Map of VPC names to their AWS resource IDs
 *                    Route tables must be created within a specific VPC
 *
 * @var igw_ids     - Map of VPC names to Internet Gateway IDs
 *                    Public route tables route 0.0.0.0/0 to these gateways
 *
 * @var subnet_ids  - Map of subnet keys to their AWS resource IDs
 *                    Used to associate route tables with their subnets
 *
 * @var common_tags - Tags applied to all route table resources
 *                    Includes environment, managed_by, and other standard tags
 *
 * @var region      - Region identifier for resource naming
 *                    Example: "nvirginia" or "london"
 */
variable "vpcs"        { type = map(any) }
variable "vpc_ids"     { type = map(string) }
variable "igw_ids"     { type = map(string) }
variable "subnet_ids"  { type = map(string) }
variable "common_tags" { type = map(string) }
variable "region"      { type = string }
