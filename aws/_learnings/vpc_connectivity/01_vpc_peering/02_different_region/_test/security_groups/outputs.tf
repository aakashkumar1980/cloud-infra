/**
 * Security Groups Module - Outputs (Cross-Region)
 */

output "bastion_sg_id" {
  value       = aws_security_group.sg_bastion.id
  description = "Security group ID for bastion instance (N. Virginia)"
}

output "vpc_a_private_sg_id" {
  value       = aws_security_group.sg_vpc_a_private.id
  description = "Security group ID for vpc_a private instance (N. Virginia)"
}

output "vpc_c_private_sg_id" {
  value       = aws_security_group.sg_vpc_c_private.id
  description = "Security group ID for vpc_c private instance (London)"
}

/** Security Group Details with Ingress Rules */
output "security_group_details" {
  value = {
    bastion = {
      name   = aws_security_group.sg_bastion.tags["Name"]
      region = "us-east-1"
      ingress_rules = [
        for idx, rule in aws_vpc_security_group_ingress_rule.bastion_all_ingress : {
          type       = rule.ip_protocol == "-1" ? "All traffic" : upper(rule.ip_protocol)
          port_range = rule.ip_protocol == "-1" ? "All" : (rule.ip_protocol == "icmp" ? "All" : (rule.from_port == rule.to_port ? tostring(rule.from_port) : "${rule.from_port}-${rule.to_port}"))
          source     = rule.cidr_ipv4
        }
      ]
    }
    vpc_a_private = {
      name   = aws_security_group.sg_vpc_a_private.tags["Name"]
      region = "us-east-1"
      ingress_rules = [
        {
          type       = upper(aws_vpc_security_group_ingress_rule.vpc_a_private_ssh_from_vpc_a.ip_protocol)
          port_range = tostring(aws_vpc_security_group_ingress_rule.vpc_a_private_ssh_from_vpc_a.from_port)
          source     = aws_vpc_security_group_ingress_rule.vpc_a_private_ssh_from_vpc_a.cidr_ipv4
        },
        {
          type       = upper(aws_vpc_security_group_ingress_rule.vpc_a_private_ssh_from_vpc_c.ip_protocol)
          port_range = tostring(aws_vpc_security_group_ingress_rule.vpc_a_private_ssh_from_vpc_c.from_port)
          source     = aws_vpc_security_group_ingress_rule.vpc_a_private_ssh_from_vpc_c.cidr_ipv4
        },
        {
          type       = upper(aws_vpc_security_group_ingress_rule.vpc_a_private_icmp_from_vpc_a.ip_protocol)
          port_range = "All"
          source     = aws_vpc_security_group_ingress_rule.vpc_a_private_icmp_from_vpc_a.cidr_ipv4
        },
        {
          type       = upper(aws_vpc_security_group_ingress_rule.vpc_a_private_icmp_from_vpc_c.ip_protocol)
          port_range = "All"
          source     = aws_vpc_security_group_ingress_rule.vpc_a_private_icmp_from_vpc_c.cidr_ipv4
        },
        {
          type       = upper(aws_vpc_security_group_ingress_rule.vpc_a_private_iperf3_from_vpc_a.ip_protocol)
          port_range = tostring(aws_vpc_security_group_ingress_rule.vpc_a_private_iperf3_from_vpc_a.from_port)
          source     = aws_vpc_security_group_ingress_rule.vpc_a_private_iperf3_from_vpc_a.cidr_ipv4
        },
        {
          type       = upper(aws_vpc_security_group_ingress_rule.vpc_a_private_iperf3_from_vpc_c.ip_protocol)
          port_range = tostring(aws_vpc_security_group_ingress_rule.vpc_a_private_iperf3_from_vpc_c.from_port)
          source     = aws_vpc_security_group_ingress_rule.vpc_a_private_iperf3_from_vpc_c.cidr_ipv4
        }
      ]
    }
    vpc_c_private = {
      name   = aws_security_group.sg_vpc_c_private.tags["Name"]
      region = "eu-west-2"
      ingress_rules = [
        {
          type       = upper(aws_vpc_security_group_ingress_rule.vpc_c_private_ssh_from_vpc_a.ip_protocol)
          port_range = tostring(aws_vpc_security_group_ingress_rule.vpc_c_private_ssh_from_vpc_a.from_port)
          source     = aws_vpc_security_group_ingress_rule.vpc_c_private_ssh_from_vpc_a.cidr_ipv4
        },
        {
          type       = upper(aws_vpc_security_group_ingress_rule.vpc_c_private_ssh_from_vpc_c.ip_protocol)
          port_range = tostring(aws_vpc_security_group_ingress_rule.vpc_c_private_ssh_from_vpc_c.from_port)
          source     = aws_vpc_security_group_ingress_rule.vpc_c_private_ssh_from_vpc_c.cidr_ipv4
        },
        {
          type       = upper(aws_vpc_security_group_ingress_rule.vpc_c_private_icmp_from_vpc_a.ip_protocol)
          port_range = "All"
          source     = aws_vpc_security_group_ingress_rule.vpc_c_private_icmp_from_vpc_a.cidr_ipv4
        },
        {
          type       = upper(aws_vpc_security_group_ingress_rule.vpc_c_private_icmp_from_vpc_c.ip_protocol)
          port_range = "All"
          source     = aws_vpc_security_group_ingress_rule.vpc_c_private_icmp_from_vpc_c.cidr_ipv4
        },
        {
          type       = upper(aws_vpc_security_group_ingress_rule.vpc_c_private_iperf3_from_vpc_a.ip_protocol)
          port_range = tostring(aws_vpc_security_group_ingress_rule.vpc_c_private_iperf3_from_vpc_a.from_port)
          source     = aws_vpc_security_group_ingress_rule.vpc_c_private_iperf3_from_vpc_a.cidr_ipv4
        },
        {
          type       = upper(aws_vpc_security_group_ingress_rule.vpc_c_private_iperf3_from_vpc_c.ip_protocol)
          port_range = tostring(aws_vpc_security_group_ingress_rule.vpc_c_private_iperf3_from_vpc_c.from_port)
          source     = aws_vpc_security_group_ingress_rule.vpc_c_private_iperf3_from_vpc_c.cidr_ipv4
        }
      ]
    }
  }
  description = "Security group details with ingress rules"
}
