/**
 * ============================================================================
 * Subnets Module - Main Configuration
 * ============================================================================
 * This module creates subnets within VPCs and manages their routing
 * configuration. Subnets are distributed across availability zones for
 * high availability and fault tolerance.
 *
 * Purpose:
 *   - Segments VPCs into smaller network ranges (subnets)
 *   - Distributes resources across multiple availability zones
 *   - Separates public and private network tiers
 *   - Configures routing for internet access (public subnets)
 *
 * Architecture:
 *   - Flattens nested subnet configurations into single map
 *   - Resolves AZ letter codes to actual AZ names
 *   - Creates route tables for public subnet internet access
 *
 * Data Flow:
 *   networking.json → var.vpcs → local.subnets_flat → aws_subnet.this
 * ============================================================================
 */

/**
 * AWS Subnet Resource
 *
 * Creates subnets within VPCs, distributing them across availability zones
 * for high availability. Each subnet is assigned a CIDR block that is a
 * subset of the parent VPC's CIDR block.
 *
 * Key Features:
 *   - Multi-AZ distribution for fault tolerance
 *   - Public/private subnet separation via tier attribute
 *   - Flexible CIDR block assignment per subnet
 *   - Standardized naming with tier, AZ, and VPC information
 *
 * Subnet Tiers:
 *   - public: Subnets with internet gateway route (internet accessible)
 *   - private: Subnets without direct internet access (internal only)
 *
 * Naming Convention:
 *   Format: subnet_{tier}_zone_{zone_letter}-{vpc_name}-{region}-{environment}-{managed_by}
 *   Example: subnet_public_zone_a-vpc_a-nvirginia-dev-terraform
 *
 * Data Transformation:
 *   The module uses local.subnets_flat (defined in locals.tf) which:
 *   1. Flattens nested subnet arrays from all VPCs
 *   2. Resolves AZ letters (a,b,c) to actual AZ names (us-east-1a, etc.)
 *   3. Creates composite keys: "vpc_name/subnet_id"
 *
 * @for_each local.subnets_flat - Flattened map of all subnets across all VPCs
 * @param vpc_id - Parent VPC ID where subnet will be created
 * @param cidr_block - IPv4 CIDR block for the subnet (subset of VPC CIDR)
 * @param availability_zone - AWS AZ name where subnet will be placed
 * @param tags - Resource tags including Name, tier, environment, etc.
 *
 * @output id - Subnet ID used by EC2 instances and other resources
 * @output cidr_block - Subnet CIDR block for network planning
 * @output availability_zone - AZ where subnet is located
 */
resource "aws_subnet" "this" {
  // Iterate over flattened subnet map from locals.tf
  // Key format: "vpc_name/subnet_id" (e.g., "vpc_a/1")
  for_each          = local.subnets_flat

  // Associate subnet with its parent VPC
  vpc_id            = var.vpc_ids[each.value.vpc_name]

  // Subnet CIDR block (must be subset of VPC CIDR)
  cidr_block        = each.value.cidr

  // AWS availability zone (resolved from letter to full name)
  availability_zone = each.value.az

  // Merge common tags with subnet-specific Name tag
  // Name includes tier (public/private), AZ, and VPC for identification
  tags = merge(var.common_tags, {
    Name   = "subnet_${each.value.name}-${each.value.vpc_name}-${var.region}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
  })
}

/**
 * NAT Gateway Module
 *
 * Creates NAT Gateways to provide internet connectivity for resources in
 * private subnets. NAT Gateways enable outbound internet access while
 * keeping private subnet resources unreachable from the internet.
 *
 * Purpose:
 *   - Enables outbound internet access for private subnet resources
 *   - Provides managed, highly available NAT functionality
 *   - Eliminates single points of failure with AWS-managed redundancy
 *
 * Architecture:
 *   - One NAT Gateway per VPC (placed in public subnet)
 *   - Requires Elastic IP for public internet connectivity
 *   - Used by private route tables for default route (0.0.0.0/0)
 *
 * NAT Gateway Placement:
 *   - vpc_a: NAT Gateway in first public subnet (zone a)
 *   - vpc_c: NAT Gateway in first public subnet (zone a)
 *
 * @source ./nat_gateway - NAT Gateway module path
 *
 * @param vpcs - VPC configurations to determine which VPCs need NAT Gateways
 * @param vpc_ids - Map of VPC names to VPC IDs for NAT Gateway association
 * @param subnet_ids - Map of subnet identifiers to subnet IDs (NAT GW in public subnet)
 * @param igw_ids - Internet Gateway IDs for dependency management
 * @param common_tags - Tags to apply to NAT Gateway resources
 * @param region - Region identifier for NAT Gateway naming
 *
 * @output nat_gateway_ids - Map of VPC names to NAT Gateway IDs
 * @output nat_gateway_public_ips - Map of VPC names to NAT Gateway public IPs
 */
module "nat_gateway" {
  source      = "./nat_gateway"
  vpcs        = var.vpcs
  vpc_ids     = var.vpc_ids
  subnet_ids  = { for k, s in aws_subnet.this : k => s.id }
  igw_ids     = var.igw_ids
  igw_names   = var.igw_names
  common_tags = var.common_tags
  region      = var.region
}

/**
 * Route Tables Module
 *
 * Creates and configures route tables for both public and private subnets.
 * This module orchestrates routing configuration to enable internet connectivity
 * through Internet Gateways (public) and NAT Gateways (private).
 *
 * Purpose:
 *   - Manages routing for public subnets (via Internet Gateway)
 *   - Manages routing for private subnets (via NAT Gateway)
 *   - Provides unified interface for route table management
 *
 * Architecture:
 *   - Public subnets: 0.0.0.0/0 → Internet Gateway (bidirectional internet access)
 *   - Private subnets: 0.0.0.0/0 → NAT Gateway (outbound only)
 *
 * Sub-modules:
 *   - route_tables_public: Creates route tables with IGW routes for public subnets
 *   - route_tables_private: Creates route tables with NAT GW routes for private subnets
 *
 * @source ./route_tables - Route tables module path
 *
 * @param vpcs - VPC configurations to identify public and private subnets
 * @param vpc_ids - VPC IDs for route table association
 * @param igw_ids - Internet Gateway IDs for public subnet routing
 * @param nat_gateway_ids - NAT Gateway IDs for private subnet routing
 * @param subnet_ids - Subnet IDs for route table associations
 * @param common_tags - Tags to apply to route table resources
 * @param region - Region identifier for resource naming
 *
 * @output public_route_table_ids - Map of public route table IDs
 * @output private_route_table_ids - Map of private route table IDs
 */
module "route_tables" {
  source          = "./route_tables"
  vpcs            = var.vpcs
  vpc_ids         = var.vpc_ids
  igw_ids         = var.igw_ids
  nat_gateway_ids = module.nat_gateway.nat_gateway_ids
  subnet_ids      = { for k, s in aws_subnet.this : k => s.id }
  common_tags     = var.common_tags
  region          = var.region
}
