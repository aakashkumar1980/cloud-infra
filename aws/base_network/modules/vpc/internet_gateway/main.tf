/**
 * Internet Gateway Module
 *
 * Creates one Internet Gateway (IGW) per VPC.
 * An IGW allows resources in public subnets to communicate with the internet.
 *
 * How it works:
 *   - Provides a target for internet-bound traffic in route tables
 *   - Performs NAT for instances with public IP addresses
 *   - Highly available and managed by AWS (no maintenance needed)
 *
 * Naming Convention:
 *   igw-{vpc_name}-{name_suffix}
 *   Example: igw-vpc_a-nvirginia-dev-terraform
 *
 * @for_each var.vpcs - Creates one IGW per VPC
 * @param vpc_id      - The VPC to attach the IGW to
 */
resource "aws_internet_gateway" "this" {
  for_each = var.vpcs
  vpc_id   = var.vpc_ids[each.key]

  tags = merge(var.tags_common, {
    Name = "igw-${each.key}-${var.name_suffix}"
  })
}
