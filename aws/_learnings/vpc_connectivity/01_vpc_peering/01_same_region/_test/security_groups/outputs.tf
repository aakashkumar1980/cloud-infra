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
