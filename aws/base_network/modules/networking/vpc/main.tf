/**
 * ============================================================================
 * VPC Module - Main Configuration
 * ============================================================================
 * This module creates Virtual Private Clouds (VPCs) and manages their core
 * networking components including Internet Gateways and Subnets.
 *
 * Purpose:
 *   - Creates isolated network environments (VPCs)
 *   - Provisions Internet Gateways for public internet connectivity
 *   - Organizes subnets across multiple availability zones
 *
 * Resource Creation Order:
 *   1. VPCs (aws_vpc.this)
 *   2. Internet Gateways (module.internet_gateway)
 *   3. Subnets and Route Tables (module.subnets)
 * ============================================================================
 */

/**
 * AWS VPC Resource
 *
 * Creates one Virtual Private Cloud per entry in var.vpcs configuration.
 * VPCs provide isolated network environments for AWS resources with
 * customizable IP address ranges (CIDR blocks).
 *
 * Key Features:
 *   - Isolated network environment per VPC
 *   - Custom CIDR block configuration
 *   - Standardized naming convention with region and environment
 *   - Tag-based resource organization
 *
 * Naming Convention:
 *   Format: {vpc_name}-{region}-{environment}-{managed_by}
 *   Example: vpc_a-nvirginia-dev-terraform
 *
 * @for_each var.vpcs - Iterates over VPC configurations from networking.json
 * @param cidr_block - IPv4 CIDR block for the VPC (e.g., "10.0.0.0/24")
 * @param tags - Resource tags including Name, environment, project, etc.
 *
 * @output id - VPC identifier used by subnets and gateways
 * @output cidr_block - VPC CIDR block for network planning
 */
resource "aws_vpc" "this" {
  // Loop over each VPC defined in var.vpcs
  // Key: VPC name (e.g., "vpc_a"), Value: VPC configuration map
  for_each   = var.vpcs

  // VPC CIDR block from networking.json config file
  // Defines the IP address range for this VPC
  cidr_block = each.value.cidr

  // Merge common tags with VPC-specific Name tag
  tags = merge(var.common_tags, {
    Name   = "${each.key}-${var.region}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
  })
}

/**
 * Internet Gateway Module
 *
 * Creates Internet Gateways (IGWs) to enable communication between resources
 * in the VPC and the internet. Each VPC gets its own dedicated IGW.
 *
 * Purpose:
 *   - Enables internet connectivity for public subnets
 *   - Provides NAT for instances with public IP addresses
 *   - Supports bidirectional internet communication
 *
 * @source ./internet_gateway - Internet Gateway module path
 *
 * @param vpcs - VPC configurations to determine which VPCs need IGWs
 * @param vpc_ids - Map of VPC names to VPC IDs for IGW attachment
 * @param common_tags - Tags to apply to IGW resources
 * @param region - Region identifier for IGW naming
 *
 * @output igw_ids - Map of VPC names to Internet Gateway IDs
 */
module "internet_gateway" {
  source      = "./internet_gateway"
  vpcs        = var.vpcs
  vpc_ids     = { for k, v in aws_vpc.this : k => v.id }
  common_tags = var.common_tags
  region      = var.region
}

/**
 * Subnets Module
 *
 * Creates subnets within VPCs and configures routing tables. Subnets are
 * distributed across multiple availability zones for high availability.
 *
 * Purpose:
 *   - Segments VPC into smaller network ranges
 *   - Distributes resources across availability zones
 *   - Separates public and private network tiers
 *   - Configures route tables for internet access
 *
 * Subnet Types:
 *   - Public: Has route to Internet Gateway, can access internet
 *   - Private: No direct internet access, uses NAT for outbound traffic
 *
 * @source ./subnets - Subnets module path
 *
 * @param vpcs - VPC configurations containing subnet definitions
 * @param vpc_ids - Map of VPC names to VPC IDs for subnet association
 * @param az_names - List of AZ names for subnet placement
 * @param az_letter_to_ix - AZ letter to index mapping for name resolution
 * @param igw_ids - Internet Gateway IDs for public route table configuration
 * @param common_tags - Tags to apply to subnet and route table resources
 * @param region - Region identifier for resource naming
 *
 * @output subnet_ids - Map of subnet identifiers to subnet IDs
 * @output route_table_public_ids - Map of public route table IDs
 */
module "subnets" {
  source           = "./subnets"
  vpcs             = var.vpcs
  vpc_ids          = { for k, v in aws_vpc.this : k => v.id }
  az_names         = var.az_names
  az_letter_to_ix  = var.az_letter_to_ix
  igw_ids          = module.internet_gateway.igw_ids
  common_tags      = var.common_tags
  region           = var.region
}

