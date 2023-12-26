/** update the tag of the default created resources by the vpc **/
resource "aws_default_route_table" "vpc-update-rt_default_tag" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id
  tags = {
    Name = "${aws_vpc.vpc.tags["Name"]}.rt_default"
  }
}
