/** update the tag of the default created resources by the vpc **/
resource "aws_default_security_group" "vpc-update-sg_default_tag" {
  vpc_id = aws_vpc.vpc.id
  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${aws_vpc.vpc.tags["Name"]}.sg_default"
  }
}
