locals {
  ingress_rules = [{
      protocol  = "icmp"
      from_port = "-1"
      to_port   = "-1"
    }, {
      protocol  = "tcp"
      from_port = "80"
      to_port   = "80"
    }, {
      protocol  = "tcp"
      from_port = "443"
      to_port   = "443"
    }
  ]

}
