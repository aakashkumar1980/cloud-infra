/**
 * VPC creation
 *
 * - one VPC per entry in var.vpcs
 * - cidr_block is taken from networking.yaml
 * - tags include name + region
 */
resource "aws_vpc" "this" {
  for_each   = var.vpcs
  cidr_block = each.value.cidr

  tags = merge(var.common_tags, {
    name   = each.key
    region = var.region
  })
}
