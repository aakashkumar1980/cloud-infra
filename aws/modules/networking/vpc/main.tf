resource "aws_vpc" "this" {
  for_each   = var.vpcs
  cidr_block = each.value.cidr

  tags = merge(var.common_tags, {
    name   = each.key
    region = var.region
  })
}
