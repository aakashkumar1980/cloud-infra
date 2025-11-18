/**
 * ============================================================================
 * VPC Module - Main Configuration
 * ============================================================================
 * This module creates Virtual Private Clouds (VPCs) and manages their core
 * networking components including Internet Gateways, Subnets, NAT Gateways,
 * and Route Tables.
 *
 * Purpose:
 *   - Creates isolated network environments (VPCs)
 *   - Provisions Internet Gateways for public internet connectivity
 *   - Provisions NAT Gateways for private subnet internet access
 *   - Organizes subnets across multiple availability zones
 *   - Configures routing for both public and private subnets
 *
 * Resource Creation Order:
 *   1. VPCs (aws_vpc.this)
 *   2. Internet Gateways (module.internet_gateway)
 *   3. Subnets, NAT Gateways, and Public Route Tables (module.subnets)
 *   4. Private Route Tables (module.route_tables_private)
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
 * Creates subnets within VPCs and configures routing tables for public subnets.
 * Subnets are distributed across multiple availability zones for high availability.
 *
 * Purpose:
 *   - Segments VPC into smaller network ranges
 *   - Distributes resources across availability zones
 *   - Separates public and private network tiers
 *   - Configures route tables for public subnet internet access
 *   - Creates NAT gateways for private subnet internet access
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
 * @output nat_gateway_ids - Map of VPC names to NAT Gateway IDs
 * @output nat_gateway_public_ips - Map of VPC names to NAT Gateway public IPs
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

/**
 * Private Route Tables Module
 *
 * Creates and configures route tables for private subnets, including default
 * routes to NAT Gateways. Private subnets use NAT Gateways to enable outbound
 * internet connectivity while remaining unreachable from the internet.
 *
 * Purpose:
 *   - Creates one route table per private subnet
 *   - Adds default route (0.0.0.0/0) pointing to NAT Gateway
 *   - Associates route tables with their respective private subnets
 *
 * Routing Logic:
 *   - Private subnets: 0.0.0.0/0 → NAT Gateway → Internet Gateway (outbound internet access)
 *   - Public subnets: Not handled by this module (no NAT route)
 *
 * @source ./subnets/route_tables/private - Private route tables module path
 *
 * @param vpcs - VPC configurations to identify private subnets
 * @param vpc_ids - VPC IDs for route table association
 * @param nat_gateway_ids - NAT Gateway IDs for default route target
 * @param subnet_ids - Subnet IDs for route table associations
 * @param common_tags - Tags to apply to route table resources
 * @param region - Region identifier for resource naming
 *
 * @output route_table_ids - Map of private route table IDs
 */
module "route_tables_private" {
  source          = "./subnets/route_tables/private"
  vpcs            = var.vpcs
  vpc_ids         = { for k, v in aws_vpc.this : k => v.id }
  nat_gateway_ids = module.subnets.nat_gateway_ids
  subnet_ids      = module.subnets.subnet_ids
  common_tags     = var.common_tags
  region          = var.region
}

