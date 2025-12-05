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

    ╔══════════════════════════════════════════════════════════════════════╗
    ║                    VPC PEERING CONNECTIVITY TEST                      ║
    ╠══════════════════════════════════════════════════════════════════════╣
    ║                                                                       ║
    ║  Step 1: SSH into Bastion (in vpc_a public subnet)                    ║
    ║  ──────────────────────────────────────────────────                   ║
    ║  ssh -i <your-key.pem> ec2-user@${module.instances.bastion_public_ip}
    ║                                                                       ║
    ║  Step 2: Run the automated connectivity test                          ║
    ║  ────────────────────────────────────────────────                     ║
    ║  ./test_connectivity.sh                                               ║
    ║                                                                       ║
    ║  Or manually test each target:                                        ║
    ║  ─────────────────────────────                                        ║
    ║  ping ${module.instances.vpc_a_private_ip}    # VPC A private (same VPC)
    ║  ping ${module.instances.vpc_b_private_ip}    # VPC B private (via peering)
    ║                                                                       ║
    ╠══════════════════════════════════════════════════════════════════════╣
    ║  Expected Results:                                                    ║
    ║  ─────────────────                                                    ║
    ║  • Bastion -> VPC A Private: SUCCESS (same VPC routing)               ║
    ║  • Bastion -> VPC B Private: SUCCESS (via VPC peering)                ║
    ║                                                                       ║
    ║  If peering is NOT working, you'll see:                               ║
    ║  ping: connect: Network is unreachable                                ║
    ║  (or timeout with no response)                                        ║
    ║                                                                       ║
    ╠══════════════════════════════════════════════════════════════════════╣
    ║  Instance Details:                                                    ║
    ║  • Bastion:         ${module.instances.bastion_private_ip} (vpc_a public subnet)
    ║  • VPC A Private:   ${module.instances.vpc_a_private_ip} (vpc_a private subnet)
    ║  • VPC B Private:   ${module.instances.vpc_b_private_ip} (vpc_b private subnet)
    ╚══════════════════════════════════════════════════════════════════════╝

  EOT
  description = "Instructions for testing VPC peering connectivity"
}

output "test_summary" {
  value = {
    bastion = {
      id         = module.instances.bastion_id
      public_ip  = module.instances.bastion_public_ip
      private_ip = module.instances.bastion_private_ip
      subnet_id  = module.instances.bastion_subnet_id
      vpc        = "vpc_a"
      role       = "jump-host"
    }
    vpc_a_private = {
      id         = module.instances.vpc_a_private_id
      public_ip  = "N/A (private subnet)"
      private_ip = module.instances.vpc_a_private_ip
      subnet_id  = module.instances.vpc_a_private_subnet_id
      vpc        = "vpc_a"
      role       = "target-same-vpc"
    }
    vpc_b_private = {
      id         = module.instances.vpc_b_private_id
      public_ip  = "N/A (private subnet)"
      private_ip = module.instances.vpc_b_private_ip
      subnet_id  = module.instances.vpc_b_private_subnet_id
      vpc        = "vpc_b"
      role       = "target-cross-vpc"
    }
    test_commands = {
      same_vpc  = "ping ${module.instances.vpc_a_private_ip}"
      cross_vpc = "ping ${module.instances.vpc_b_private_ip}"
      automated = "./test_connectivity.sh"
    }
  }
  description = "Summary of test instances"
}
