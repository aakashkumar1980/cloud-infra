locals {
  firewall = {
    ingress = {
      standard_rules = [{
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
        }, {
        protocol   = "tcp"
        from_port  = "3389"
        to_port    = "3389"
        cidr_block = "0.0.0.0/0"
        }
      ]
      epidermal_port_rules = [{
        protocol   = "tcp"
        from_port  = "1024"
        to_port    = "65535"
        cidr_block = "0.0.0.0/0"
      }]
    }

    egress = [{
      protocol   = "all"
      from_port  = "-1"
      to_port    = "-1"
      cidr_block = "0.0.0.0/0"
      }
    ]
  }
}
