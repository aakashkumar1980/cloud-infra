/**
 * Test Module Outputs
 *
 * Provides information needed to run connectivity tests.
 */

/** Key Pair Outputs */
output "key_name" {
  value       = module.key_pair.key_name
  description = "Name of the SSH key pair"
}

output "private_key_pem" {
  value       = module.key_pair.private_key_pem
  description = "Private key in PEM format - save to file: terraform output -raw private_key_pem > key.pem && chmod 400 key.pem"
  sensitive   = true
}

/** Instance Outputs */
output "bastion_public_ip" {
  value       = module.instances.bastion_public_ip
  description = "Public IP of Bastion (SSH target)"
}

output "bastion_private_ip" {
  value       = module.instances.bastion_private_ip
  description = "Private IP of Bastion"
}

output "vpc_a_private_ip" {
  value       = module.instances.vpc_a_private_ip
  description = "Private IP of VPC A private instance (same VPC target)"
}

output "vpc_b_private_ip" {
  value       = module.instances.vpc_b_private_ip
  description = "Private IP of VPC B private instance (cross-VPC target)"
}

output "test_instructions" {
  value = <<-EOT

    ╔═══════════════════════════════════════════════════════════════════════╗
    ║                    VPC PEERING CONNECTIVITY TEST                      ║
    ╠═══════════════════════════════════════════════════════════════════════╣
    ║  terraform output -raw test_private_key_pem > _test\${module.key_pair.key_name}.pem ║
    ║  chmod 400 _test\${module.key_pair.key_name}.pem (linux only)       ║
    ║                                                                       ║
    ║  Step 1: SSH into Bastion EC2@${module.instances.bastion_private_ip} (in vpc_a public subnet) ║
    ║  ──────────────────────────────────────────────────                   ║
    ║  ssh -i _test\${module.key_pair.key_name}.pem ec2-user@${module.instances.bastion_public_ip} ║
    ║                                                                       ║
    ║  Step 2: Then SSH into VPC A private instance and run the automated connectivity test to VPC A private instance(${module.instances.vpc_b_private_ip}) ║
    ║  ────────────────────────────────────────────────                     ║
    ║  ssh ec2-user@${module.instances.vpc_a_private_ip} ║
    ║  ./test_connectivity.sh                                               ║
    ║                                                                       ║
    ╚═══════════════════════════════════════════════════════════════════════╝

  EOT
  description = "Instructions for testing VPC peering connectivity"
}

output "test_summary" {
  value = {
    security_groups = module.security_groups.security_group_details
    key_pair        = module.key_pair.key_name
    instances       = module.instances.instance_details
  }
  description = "Summary of test resources: security groups with ingress rules, key pair, and EC2 instances"
}
