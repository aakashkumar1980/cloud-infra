/**
 * Instances Module - Outputs
 */

output "instance_a_id" {
  value       = aws_instance.instance_a.id
  description = "Instance A ID"
}

output "instance_a_public_ip" {
  value       = aws_instance.instance_a.public_ip
  description = "Public IP of Instance A (SSH target)"
}

output "instance_a_private_ip" {
  value       = aws_instance.instance_a.private_ip
  description = "Private IP of Instance A"
}

output "instance_a_subnet_id" {
  value       = aws_instance.instance_a.subnet_id
  description = "Subnet ID of Instance A"
}

output "instance_b_id" {
  value       = aws_instance.instance_b.id
  description = "Instance B ID"
}

output "instance_b_private_ip" {
  value       = aws_instance.instance_b.private_ip
  description = "Private IP of Instance B (ping target)"
}

output "instance_b_subnet_id" {
  value       = aws_instance.instance_b.subnet_id
  description = "Subnet ID of Instance B"
}
