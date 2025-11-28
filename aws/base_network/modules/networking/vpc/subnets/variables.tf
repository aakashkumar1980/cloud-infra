/**
 * Input Variables
 *
 * @var vpcs            - Map of VPC configs with subnet definitions
 * @var vpc_ids         - Map of VPC names to VPC IDs
 * @var az_names        - List of availability zone names in the region
 * @var az_letter_to_ix - Maps zone letters (a,b,c) to array indices (0,1,2)
 * @var igw_ids         - Map of VPC names to Internet Gateway IDs
 * @var igw_names       - Map of VPC names to Internet Gateway Name tags
 * @var common_tags     - Tags applied to all resources
 * @var region          - Region identifier for naming
 */
variable "vpcs"            { type = map(any) }
variable "vpc_ids"         { type = map(string) }
variable "az_names"        { type = list(string) }
variable "az_letter_to_ix" { type = map(number) }
variable "igw_ids"         { type = map(string) }
variable "igw_names"       { type = map(string) }
variable "common_tags"     { type = map(string) }
variable "region"          { type = string }
