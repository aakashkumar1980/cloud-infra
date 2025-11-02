resource "aws_security_group_rule" "add-ingress_rule" {
  type = "ingress"

  from_port   = var.from_port
  to_port     = var.to_port
  protocol    = var.protocol
  cidr_blocks = var.cidr_blocks
  description = var.description

  security_group_id        = var.securitygroup_id
  source_security_group_id = var.source_security_group_id
}
