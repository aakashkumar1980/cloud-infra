resource "aws_network_acl_rule" "add-ingress_rule" {
  egress      = false
  rule_action = "allow"

  rule_number = var.rule_number
  protocol    = var.protocol
  cidr_block  = var.cidr_block
  from_port   = var.from_port
  to_port     = var.to_port

  icmp_type = (var.protocol=="icmp")? var.from_port:null
  icmp_code = (var.protocol=="icmp")? var.to_port:null

  network_acl_id = var.nacl_id

}
