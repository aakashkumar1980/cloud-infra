/**
 * Networking Module
 *
 * This is the main entry point for creating network infrastructure.
 * It delegates all work to the VPC module, which creates:
 *   - VPCs with custom CIDR blocks
 *   - Internet Gateways for public internet access
 *   - Subnets distributed across availability zones
 *   - NAT Gateways for private subnet internet access
 *   - Route Tables for traffic routing
 *
 * @param vpcs            - VPC configurations from networking.json
 * @param az_names        - List of availability zones in the region
 * @param az_letter_to_ix - Maps zone letters (a,b,c) to indices (0,1,2)
 * @param common_tags     - Tags to apply to all resources
 * @param region          - Region identifier for resource naming
 */
module "vpc" {
  source          = "./vpc"
  vpcs            = var.vpcs
  az_names        = var.az_names
  az_letter_to_ix = var.az_letter_to_ix
  common_tags     = var.common_tags
  region          = var.region
}
