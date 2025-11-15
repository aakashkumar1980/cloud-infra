/**
 * Internet Gateway creation
 *
 * - one IGW per VPC
 * - provides internet connectivity for public subnets
 * - tags include vpc name + region
 */
resource "aws_internet_gateway" "this" {
  // loop over each VPC defined in var.vpcs
  for_each = var.vpcs

  // Attach to the corresponding VPC
  vpc_id = var.vpc_ids[each.key]

  tags = merge(var.common_tags, {
    Name = "igw-${each.key}-${var.region}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
  })
}
