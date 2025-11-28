/**
 * Input Variables for Private Route Tables
 *
 * @var vpcs            - VPC configurations containing subnet definitions
 *                        Used to identify which subnets are private (tier = "private")
 *
 * @var vpc_ids         - Map of VPC names to their AWS resource IDs
 *                        Route tables must be created within a specific VPC
 *
 * @var nat_gateway_ids - Map of VPC names to NAT Gateway IDs
 *                        Private route tables route 0.0.0.0/0 to these gateways
 *                        Only VPCs with NAT Gateways will have private route tables
 *
 * @var subnet_ids      - Map of subnet keys to their AWS resource IDs
 *                        Used to associate route tables with their subnets
 *
 * @var common_tags     - Tags applied to all route table resources
 *                        Includes environment, managed_by, and other standard tags
 *
 * @var region          - Region identifier for resource naming
 *                        Example: "nvirginia" or "london"
 */
variable "vpcs"            { type = map(any) }
variable "vpc_ids"         { type = map(string) }
variable "nat_gateway_ids" { type = map(string) }
variable "subnet_ids"      { type = map(string) }
variable "common_tags"     { type = map(string) }
variable "region"          { type = string }
