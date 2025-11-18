/**
 * ============================================================================
 * NAT Gateway Module - Main Configuration
 * ============================================================================
 * This module creates NAT Gateways to provide internet connectivity for
 * resources in private subnets. NAT Gateways enable instances in private
 * subnets to connect to the internet while remaining unreachable from the
 * internet.
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
 * Dependencies:
 *   - Requires VPC and public subnets to be created first
 *   - Requires Elastic IP allocation
 *   - Used by private route tables for outbound internet access
 *
 * Local Variables:
 *   See locals.tf for local variable definitions including:
 *   - nat_gateway_vpcs: VPCs that need NAT gateways
 *   - public_subnets: Flattened map of public subnets
 *   - nat_gateway_subnets: First public subnet per VPC for NAT gateway placement
 * ============================================================================
 */

/**
 * AWS Elastic IP Resource for NAT Gateway
 *
 * Creates one Elastic IP per NAT Gateway. The EIP provides a static public
 * IPv4 address for the NAT Gateway, ensuring outbound connections from
 * private subnets have a consistent source IP.
 *
 * Key Characteristics:
 *   - Static public IPv4 address
 *   - Persists independently of NAT Gateway lifecycle
 *   - Required for NAT Gateway creation
 *   - Billed when not associated with running instance
 *
 * Naming Convention:
 *   Format: eip-natgw-{vpc_name}-{region}-{environment}-{managed_by}
 *   Example: eip-natgw-vpc_a-nvirginia-dev-terraform
 *
 * @for_each local.nat_gateway_subnets - One EIP per NAT Gateway
 * @param domain - "vpc" indicates EIP is for use in VPC
 * @param tags - Resource tags including Name, environment, project, etc.
 *
 * @output public_ip - The allocated Elastic IP address
 * @output allocation_id - EIP allocation ID used by NAT Gateway
 */
resource "aws_eip" "nat" {
  // Create one EIP per VPC that needs a NAT Gateway
  for_each = local.nat_gateway_subnets

  // Specify that this EIP is for use in a VPC
  domain = "vpc"

  // Merge common tags with EIP-specific Name tag
  tags = merge(var.common_tags, {
    Name = "eip-natgw-${each.key}-${var.region}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
  })
}

/**
 * AWS NAT Gateway Resource
 *
 * Creates one NAT Gateway per VPC to enable internet connectivity for
 * private subnets. NAT Gateways are highly available within a single AZ
 * and are managed by AWS.
 *
 * Key Characteristics:
 *   - Highly available within a single availability zone
 *   - Managed by AWS (patching, scaling, redundancy)
 *   - Supports up to 45 Gbps of bandwidth
 *   - Automatically scales to handle traffic
 *
 * Placement Strategy:
 *   - Placed in public subnet for internet connectivity
 *   - Uses first public subnet alphabetically by zone
 *   - Requires Internet Gateway in the VPC
 *
 * Naming Convention:
 *   Format: natgw-{vpc_name}-{region}-{environment}-{managed_by}
 *   Example: natgw-vpc_a-nvirginia-dev-terraform
 *
 * @for_each local.nat_gateway_subnets - One NAT Gateway per VPC
 * @param allocation_id - EIP allocation ID for the NAT Gateway
 * @param subnet_id - Public subnet where NAT Gateway will be created
 * @param tags - Resource tags including Name, environment, project, etc.
 *
 * @output id - NAT Gateway ID used in private route tables
 * @output public_ip - Public IP address of the NAT Gateway
 */
resource "aws_nat_gateway" "this" {
  // Create one NAT Gateway per VPC that needs one
  for_each = local.nat_gateway_subnets

  // Associate with the Elastic IP created above
  allocation_id = aws_eip.nat[each.key].id

  // Place NAT Gateway in the public subnet (first public subnet by zone)
  subnet_id = var.subnet_ids[each.value]

  // Merge common tags with NAT Gateway-specific Name tag
  tags = merge(var.common_tags, {
    Name = "natgw-${each.key}-${var.region}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
  })

  // Ensure Internet Gateway exists before creating NAT Gateway
  // NAT Gateway requires IGW for internet connectivity
  depends_on = [var.igw_ids]
}
