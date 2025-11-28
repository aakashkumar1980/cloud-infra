/**
 * Input Variables
 *
 * @var vpcs        - Map of VPC configs (to find public subnets)
 * @var vpc_ids     - Map of VPC names to VPC IDs
 * @var subnet_ids  - Map of subnet keys to subnet IDs
 * @var igw_ids     - Map of VPC names to IGW IDs (NAT GW depends on IGW)
 * @var igw_names   - Map of VPC names to IGW names (for output display)
 * @var common_tags - Tags applied to all resources
 * @var region      - Region identifier for naming
 */
variable "vpcs"        { type = map(any) }
variable "vpc_ids"     { type = map(string) }
variable "subnet_ids"  { type = map(string) }
variable "igw_ids"     { type = map(string) }
variable "igw_names"   { type = map(string) }
variable "common_tags" { type = map(string) }
variable "region"      { type = string }
