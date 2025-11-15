/**
 * VPC creation
 *
 * - one VPC per entry in var.vpcs
 * - cidr_block is taken from networking.yaml
 * - tags include name + region
 */
resource "aws_vpc" "this" {
  // loop over each VPC defined in var.vpcs
  for_each   = var.vpcs

  // VPC CIDR block from config
  cidr_block = each.value.cidr
  tags = merge(var.common_tags, {
    Name   = "${each.key}-${var.region}-${var.common_tags["environment"]}-${var.common_tags["managed_by"]}"
  })
}
