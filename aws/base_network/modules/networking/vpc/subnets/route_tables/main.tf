/**
 * ============================================================================
 * Route Tables Module - Main Configuration
 * ============================================================================
 * This module manages routing configuration for both public and private
 * subnets. It orchestrates the creation of route tables, routes, and
 * associations for internet connectivity.
 *
 * Purpose:
 *   - Manages public subnet routing (via Internet Gateway)
 *   - Manages private subnet routing (via NAT Gateway)
 *   - Provides a unified interface for route table management
 *
 * Architecture:
 *   - Public Subnets → IGW (direct internet access)
 *   - Private Subnets → NAT Gateway → IGW (outbound only)
 *
 * Sub-modules:
 *   - route_tables_public: Handles public subnet routing
 *   - route_tables_private: Handles private subnet routing
 * ============================================================================
 */

/**
 * Public Route Tables Module
 *
 * Creates and configures route tables for public subnets, including default
 * routes to Internet Gateways. Public subnets require explicit routing to
 * IGWs to enable internet connectivity.
 *
 * Purpose:
 *   - Creates one route table per public subnet
 *   - Adds default route (0.0.0.0/0) pointing to Internet Gateway
 *   - Associates route tables with their respective public subnets
 *
 * Routing Logic:
 *   - Public subnets: 0.0.0.0/0 → Internet Gateway (internet access)
 *
 * @source ./public - Public route tables module path
 *
 * @param vpcs - VPC configurations to identify public subnets
 * @param vpc_ids - VPC IDs for route table association
 * @param igw_ids - Internet Gateway IDs for default route target
 * @param subnet_ids - Subnet IDs for route table associations
 * @param common_tags - Tags to apply to route table resources
 * @param region - Region identifier for resource naming
 *
 * @output route_table_ids - Map of public route table IDs
 */
module "route_tables_public" {
  source      = "./public"
  vpcs        = var.vpcs
  vpc_ids     = var.vpc_ids
  igw_ids     = var.igw_ids
  subnet_ids  = var.subnet_ids
  common_tags = var.common_tags
  region      = var.region
}

/**
 * Private Route Tables Module
 *
 * Creates and configures route tables for private subnets, including default
 * routes to NAT Gateways. Private subnets use NAT Gateways for outbound
 * internet access while remaining unreachable from the internet.
 *
 * Purpose:
 *   - Creates one route table per private subnet
 *   - Adds default route (0.0.0.0/0) pointing to NAT Gateway
 *   - Associates route tables with their respective private subnets
 *
 * Routing Logic:
 *   - Private subnets: 0.0.0.0/0 → NAT Gateway (outbound internet access)
 *
 * @source ./private - Private route tables module path
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
  source          = "./private"
  vpcs            = var.vpcs
  vpc_ids         = var.vpc_ids
  nat_gateway_ids = var.nat_gateway_ids
  subnet_ids      = var.subnet_ids
  common_tags     = var.common_tags
  region          = var.region
}
