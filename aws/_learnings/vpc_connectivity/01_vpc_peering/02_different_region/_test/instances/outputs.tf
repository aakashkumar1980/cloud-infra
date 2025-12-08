/**
 * Instances Module - Outputs (Cross-Region)
 */

/** Bastion Instance Outputs (N. Virginia) */
output "bastion_id" {
  value       = aws_instance.bastion_ec2.id
  description = "Bastion instance ID (N. Virginia)"
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

/** VPC A Private Instance Outputs (N. Virginia) */
output "vpc_a_private_id" {
  value       = aws_instance.vpc_a_private_ec2.id
  description = "VPC A private instance ID (N. Virginia)"
}

output "vpc_a_private_ip" {
  value       = aws_instance.vpc_a_private_ec2.private_ip
  description = "Private IP of VPC A private instance (ping target)"
}

output "vpc_a_private_subnet_id" {
  value       = aws_instance.vpc_a_private_ec2.subnet_id
  description = "Subnet ID of VPC A private instance"
}

/** VPC C Private Instance Outputs (London) */
output "vpc_c_private_id" {
  value       = aws_instance.vpc_c_private_ec2.id
  description = "VPC C private instance ID (London)"
}

output "vpc_c_private_ip" {
  value       = aws_instance.vpc_c_private_ec2.private_ip
  description = "Private IP of VPC C private instance (cross-region ping target)"
}

output "vpc_c_private_subnet_id" {
  value       = aws_instance.vpc_c_private_ec2.subnet_id
  description = "Subnet ID of VPC C private instance"
}

/** Instance Details with Tag Names */
output "instance_details" {
  value = {
    bastion = {
      name       = aws_instance.bastion_ec2.tags["Name"]
      private_ip = aws_instance.bastion_ec2.private_ip
      public_ip  = aws_instance.bastion_ec2.public_ip
      region     = "us-east-1"
    }
    vpc_a_private = {
      name       = aws_instance.vpc_a_private_ec2.tags["Name"]
      private_ip = aws_instance.vpc_a_private_ec2.private_ip
      public_ip  = null
      region     = "us-east-1"
    }
    vpc_c_private = {
      name       = aws_instance.vpc_c_private_ec2.tags["Name"]
      private_ip = aws_instance.vpc_c_private_ec2.private_ip
      public_ip  = null
      region     = "eu-west-2"
    }
  }
  description = "Instance details with tag names, IPs, and regions"
}
