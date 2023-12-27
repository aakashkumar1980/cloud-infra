resource "aws_security_group" "securitygroup" {
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  name = "${var.tag_path}.sg_${var.entity_name}"
  tags = {
    Name = "${var.tag_path}.sg_${var.entity_name}"
  }

}
