/**
 * ============================================================================
 * Internet Gateway Module - Main Configuration
 * ============================================================================
 * This module creates Internet Gateways (IGWs) to provide internet
 * connectivity for VPCs. IGWs enable resources in public subnets to
 * communicate with the internet.
 *
 * Purpose:
 *   - Enables bidirectional internet communication for VPC resources
 *   - Provides NAT functionality for instances with public IPs
 *   - Required for public subnet internet access
 *
 * Architecture:
 *   - One Internet Gateway per VPC (1:1 relationship)
 *   - IGW is horizontally scaled, redundant, and highly available
 *   - No bandwidth constraints imposed by the IGW itself
 *
 * Dependencies:
 *   - Requires VPC to be created first (via var.vpc_ids)
 *   - Used by public route tables for default route (0.0.0.0/0)
 * ============================================================================
 */

/**
 * AWS Internet Gateway Resource
 *
 * Creates one Internet Gateway per VPC to enable internet connectivity.
 * An IGW serves two purposes:
 *   1. Provides a target in VPC route tables for internet-routable traffic
 *   2. Performs network address translation (NAT) for instances with public IPs
 *
 * Key Characteristics:
 *   - Highly available and redundant (AWS-managed)
 *   - Horizontally scaled by AWS automatically
 *   - Supports both IPv4 and IPv6 traffic
 *   - No throughput limits or bandwidth constraints
 *
 * Naming Convention:
 *   Format: igw-{vpc_name}-{region}-{environment}-{managed_by}
 *   Example: igw-vpc_a-nvirginia-dev-terraform
 *
 * @for_each var.vpcs - Iterates over VPC configurations to create one IGW per VPC
 * @param vpc_id - The VPC ID to which the IGW will be attached
 * @param tags - Resource tags including Name, environment, project, etc.
 *
 * @output id - Internet Gateway ID used in route table configurations
 * @output vpc_id - Associated VPC ID for reference
 */
resource "aws_internet_gateway" "this" {
  // Loop over each VPC defined in var.vpcs
  // Creates one IGW per VPC for internet connectivity
  for_each = var.vpcs

  // Attach IGW to the corresponding VPC
  // Uses vpc_ids map to lookup the VPC ID by name
  vpc_id = var.vpc_ids[each.key]

  // Merge common tags with IGW-specific Name tag
  // Name follows standard convention for easy identification
  tags = merge(var.common_tags, {
    Name = "igw-${each.key}-${var.region}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
  })
}
