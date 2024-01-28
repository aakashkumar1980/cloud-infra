locals {
  flattened_ingress_rules = flatten([
    for rule_idx, rule in var.ingress-rules_map : [
      for cidr_block in rule.cidr_blocks : {
        description = rule.description
        protocol    = rule.protocol
        from_port   = rule.from_port
        to_port     = rule.to_port
        cidr_block  = cidr_block
      }
    ]
  ])
}
