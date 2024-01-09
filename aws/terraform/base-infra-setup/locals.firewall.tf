locals {
  firewall = {
    ingress_rules = [{
      # ping
      protocol   = "icmp"
      from_port  = "-1"
      to_port    = "-1"
      cidr_block = "0.0.0.0/0"
      }, {
      protocol   = "tcp"
      from_port  = "80"
      to_port    = "80"
      cidr_block = "0.0.0.0/0"
      }, {
      protocol   = "tcp"
      from_port  = "443"
      to_port    = "443"
      cidr_block = "0.0.0.0/0"
      }, {
      protocol   = "tcp"
      from_port  = "22"
      to_port    = "22"
      cidr_block = "0.0.0.0/0"
      }
    ]
    egress_rules = [{
      protocol   = "all"
      from_port  = "-1"
      to_port    = "-1"
      cidr_block = "0.0.0.0/0"
      }
      # custom tcp-> 1024-65535
    ]
  }
}
