data "aws_route_table" "route_table" {
  filter {
    name   = "tag:Name"
    values = ["${var.tag_path}.rt_private"]
  }
}
