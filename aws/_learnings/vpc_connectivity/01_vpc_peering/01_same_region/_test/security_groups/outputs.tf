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

/** Security Group Details with Egress Rules */
output "security_group_details" {
  value = {
    bastion = {
      name = aws_security_group.sg_bastion.tags["Name"]
      egress_rules = [
        for idx, rule in aws_vpc_security_group_egress_rule.bastion_all_egress : {
          type        = rule.ip_protocol == "-1" ? "All traffic" : upper(rule.ip_protocol)
          port_range  = rule.ip_protocol == "-1" ? "All" : (rule.from_port == rule.to_port ? tostring(rule.from_port) : "${rule.from_port}-${rule.to_port}")
          destination = rule.cidr_ipv4
        }
      ]
    }
    vpc_a_private = {
      name = aws_security_group.sg_vpc_a_private.tags["Name"]
      egress_rules = [
        for idx, rule in aws_vpc_security_group_egress_rule.vpc_a_private_all_egress : {
          type        = rule.ip_protocol == "-1" ? "All traffic" : upper(rule.ip_protocol)
          port_range  = rule.ip_protocol == "-1" ? "All" : (rule.from_port == rule.to_port ? tostring(rule.from_port) : "${rule.from_port}-${rule.to_port}")
          destination = rule.cidr_ipv4
        }
      ]
    }
    vpc_b_private = {
      name = aws_security_group.sg_vpc_b_private.tags["Name"]
      egress_rules = [
        for idx, rule in aws_vpc_security_group_egress_rule.vpc_b_private_all_egress : {
          type        = rule.ip_protocol == "-1" ? "All traffic" : upper(rule.ip_protocol)
          port_range  = rule.ip_protocol == "-1" ? "All" : (rule.from_port == rule.to_port ? tostring(rule.from_port) : "${rule.from_port}-${rule.to_port}")
          destination = rule.cidr_ipv4
        }
      ]
    }
  }
  description = "Security group details with egress rules"
}
