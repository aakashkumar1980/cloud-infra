/**
 * Input Variables
 *
 * @var vpcs        - Map of VPC configurations (used to determine how many IGWs to create)
 * @var vpc_ids     - Map of VPC names to VPC IDs (for attaching IGW to VPC)
 * @var common_tags - Tags applied to all resources
 * @var region      - Region identifier for naming (e.g., "nvirginia")
 */
variable "vpcs"        { type = map(any) }
variable "vpc_ids"     { type = map(string) }
variable "common_tags" { type = map(string) }
variable "region"      { type = string }
