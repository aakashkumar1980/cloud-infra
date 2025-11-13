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
    name   = each.key
    region = var.region
  })
}
