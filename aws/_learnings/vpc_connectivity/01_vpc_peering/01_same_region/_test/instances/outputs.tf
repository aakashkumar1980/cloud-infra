/**
 * Instances Module - Outputs
 */

/** Bastion Instance Outputs */
output "bastion_id" {
  value       = aws_instance.bastion_ec2.id
  description = "Bastion instance ID"
}

output "bastion_public_ip" {
  value       = aws_instance.bastion_ec2.public_ip
  description = "Public IP of bastion (SSH target)"
}

output "bastion_private_ip" {
  value       = aws_instance.bastion_ec2.private_ip
  description = "Private IP of bastion"
}

output "bastion_subnet_id" {
  value       = aws_instance.bastion_ec2.subnet_id
  description = "Subnet ID of bastion"
}

/** VPC A Private Instance Outputs */
output "vpc_a_private_id" {
  value       = aws_instance.vpc_a_private_ec2.id
  description = "VPC A private instance ID"
}

output "vpc_a_private_ip" {
  value       = aws_instance.vpc_a_private_ec2.private_ip
  description = "Private IP of VPC A private instance (ping target)"
}

output "vpc_a_private_subnet_id" {
  value       = aws_instance.vpc_a_private_ec2.subnet_id
  description = "Subnet ID of VPC A private instance"
}

/** VPC B Private Instance Outputs */
output "vpc_b_private_id" {
  value       = aws_instance.vpc_b_private_ec2.id
  description = "VPC B private instance ID"
}

output "vpc_b_private_ip" {
  value       = aws_instance.vpc_b_private_ec2.private_ip
  description = "Private IP of VPC B private instance (cross-VPC ping target)"
}

output "vpc_b_private_subnet_id" {
  value       = aws_instance.vpc_b_private_ec2.subnet_id
  description = "Subnet ID of VPC B private instance"
}
