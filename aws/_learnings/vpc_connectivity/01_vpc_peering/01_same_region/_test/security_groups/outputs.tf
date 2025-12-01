/**
 * Security Groups Module - Outputs
 */

output "instance_a_sg_id" {
  value       = aws_security_group.sg_instance_a.id
  description = "Security group ID for test instance A"
}

output "instance_b_sg_id" {
  value       = aws_security_group.sg_instance_b.id
  description = "Security group ID for test instance B"
}
