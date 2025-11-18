/**
 * ============================================================================
 * Networking Module - Main Configuration
 * ============================================================================
 * This module serves as the primary networking orchestrator, delegating VPC
 * creation, subnet configuration, and routing setup to specialized sub-modules.
 *
 * Purpose:
 *   - Provides a unified interface for networking infrastructure
 *   - Delegates resource creation to focused sub-modules
 *   - Simplifies multi-region networking deployments
 *
 * Architecture:
 *   main.tf (this file) → vpc module → internet_gateway + subnets modules
 *
 * @module vpc - Creates VPCs and delegates to sub-modules
 * ============================================================================
 */

/**
 * VPC Module Invocation
 *
 * Creates Virtual Private Clouds (VPCs) and orchestrates the creation of
 * related networking components including:
 *   - VPCs with specified CIDR blocks
 *   - Internet Gateways for public internet access
 *   - Subnets (public and private) across availability zones
 *   - Route tables for subnet routing configuration
 *
 * @source ./vpc - VPC module source path
 *
 * @param vpcs - Map of VPC configurations with CIDR blocks and subnet definitions
 * @param az_names - List of availability zone names for subnet placement
 * @param az_letter_to_ix - Mapping of AZ letters to indices for name resolution
 * @param common_tags - Tags to apply to all networking resources
 * @param region - AWS region identifier for resource naming
 *
 * @outputs vpc_ids, igw_ids, subnet_ids, route_table_public_ids
 */
module "vpc" {
  source          = "./vpc"
  vpcs            = var.vpcs
  az_names        = var.az_names
  az_letter_to_ix = var.az_letter_to_ix
  common_tags     = var.common_tags
  region          = var.region
}
