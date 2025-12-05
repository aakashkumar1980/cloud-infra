/**
 * Security Groups Module - Outputs
 */

output "bastion_sg_id" {
  value       = aws_security_group.sg_bastion.id
  description = "Security group ID for bastion instance"
}

output "vpc_a_private_sg_id" {
  value       = aws_security_group.sg_vpc_a_private.id
  description = "Security group ID for vpc_a private instance"
}

output "vpc_b_private_sg_id" {
  value       = aws_security_group.sg_vpc_b_private.id
  description = "Security group ID for vpc_b private instance"
}

/** Security Group Details with Ingress Rules */
output "security_group_details" {
  value = {
    bastion = {
      name = aws_security_group.sg_bastion.tags["Name"]
      ingress_rules = [
        for idx, rule in aws_vpc_security_group_ingress_rule.bastion_all_ingress : {
          type       = rule.ip_protocol == "-1" ? "All traffic" : upper(rule.ip_protocol)
          port_range = rule.ip_protocol == "-1" ? "All" : (rule.ip_protocol == "icmp" ? "All" : (rule.from_port == rule.to_port ? tostring(rule.from_port) : "${rule.from_port}-${rule.to_port}"))
          source     = rule.cidr_ipv4
        }
      ]
    }
    vpc_a_private = {
      name = aws_security_group.sg_vpc_a_private.tags["Name"]
      ingress_rules = [
        {
          type       = upper(aws_vpc_security_group_ingress_rule.vpc_a_private_ssh_from_vpc_a.ip_protocol)
          port_range = tostring(aws_vpc_security_group_ingress_rule.vpc_a_private_ssh_from_vpc_a.from_port)
          source     = aws_vpc_security_group_ingress_rule.vpc_a_private_ssh_from_vpc_a.cidr_ipv4
        },
        {
          type       = upper(aws_vpc_security_group_ingress_rule.vpc_a_private_icmp_from_vpc_a.ip_protocol)
          port_range = "All"
          source     = aws_vpc_security_group_ingress_rule.vpc_a_private_icmp_from_vpc_a.cidr_ipv4
        },
        {
          type       = upper(aws_vpc_security_group_ingress_rule.vpc_a_private_icmp_from_vpc_b.ip_protocol)
          port_range = "All"
          source     = aws_vpc_security_group_ingress_rule.vpc_a_private_icmp_from_vpc_b.cidr_ipv4
        },
        {
          type       = upper(aws_vpc_security_group_ingress_rule.vpc_a_private_iperf3_from_vpc_a.ip_protocol)
          port_range = tostring(aws_vpc_security_group_ingress_rule.vpc_a_private_iperf3_from_vpc_a.from_port)
          source     = aws_vpc_security_group_ingress_rule.vpc_a_private_iperf3_from_vpc_a.cidr_ipv4
        }
      ]
    }
    vpc_b_private = {
      name = aws_security_group.sg_vpc_b_private.tags["Name"]
      ingress_rules = [
        {
          type       = upper(aws_vpc_security_group_ingress_rule.vpc_b_private_ssh_from_vpc_a.ip_protocol)
          port_range = tostring(aws_vpc_security_group_ingress_rule.vpc_b_private_ssh_from_vpc_a.from_port)
          source     = aws_vpc_security_group_ingress_rule.vpc_b_private_ssh_from_vpc_a.cidr_ipv4
        },
        {
          type       = upper(aws_vpc_security_group_ingress_rule.vpc_b_private_icmp_from_vpc_a.ip_protocol)
          port_range = "All"
          source     = aws_vpc_security_group_ingress_rule.vpc_b_private_icmp_from_vpc_a.cidr_ipv4
        },
        {
          type       = upper(aws_vpc_security_group_ingress_rule.vpc_b_private_iperf3_from_vpc_a.ip_protocol)
          port_range = tostring(aws_vpc_security_group_ingress_rule.vpc_b_private_iperf3_from_vpc_a.from_port)
          source     = aws_vpc_security_group_ingress_rule.vpc_b_private_iperf3_from_vpc_a.cidr_ipv4
        }
      ]
    }
  }
  description = "Security group details with ingress rules"
}
