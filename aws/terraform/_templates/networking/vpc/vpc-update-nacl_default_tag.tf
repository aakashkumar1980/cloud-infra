/** update the tag of the default created resources by the vpc **/
resource "aws_default_network_acl" "vpc-update-nacl_default_tag" {
  default_network_acl_id = aws_vpc.vpc.default_network_acl_id
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = {
    Name = "${aws_vpc.vpc.tags["Name"]}.nacl_default"
  }
}
