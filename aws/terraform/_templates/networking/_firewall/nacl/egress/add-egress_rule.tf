resource "aws_network_acl_rule" "add-egress_rule" {
  egress      = true
  rule_action = "allow"

  rule_number = var.rule_number
  protocol    = var.protocol
  cidr_block  = var.cidr_block
  from_port   = var.from_port
  to_port     = var.to_port

  network_acl_id = var.nacl_id

}
