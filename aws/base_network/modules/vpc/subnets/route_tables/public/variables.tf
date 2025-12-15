/**
 * Input Variables for Public Route Tables
 *
 * @var vpcs              - VPC configurations containing subnet definitions
 *                          Used to identify which subnets are public (tier = "public")
 *
 * @var vpc_ids           - Map of VPC names to their AWS resource IDs
 *                          Route tables must be created within a specific VPC
 *
 * @var igw_ids           - Map of VPC names to Internet Gateway IDs
 *                          Public route tables route 0.0.0.0/0 to these gateways
 *
 * @var public_subnet_ids - Map of public subnet keys to their AWS resource IDs
 *                          Used to associate route tables with public subnets
 *
 * @var tags_common       - Tags applied to all route table resources
 *                          Includes environment, managed_by, and other standard tags
 *
 * @var name_suffix       - Standard suffix for resource naming
 *                          Format: {region}-{environment}-{managed_by}
 *                          Example: "nvirginia-dev-terraform"
 */
variable "vpcs"              { type = map(any) }
variable "vpc_ids"           { type = map(string) }
variable "igw_ids"           { type = map(string) }
variable "public_subnet_ids" { type = map(string) }
variable "tags_common"       { type = map(string) }
variable "name_suffix"       { type = string }
