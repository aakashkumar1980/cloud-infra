resource "aws_route_table" "rt" {
  vpc_id = var.vpc_id

  tags = {
    "Name" = "${var.tag_path}.rt_${var.entity_name}"
  }
}
