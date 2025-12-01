/**
 * Test Module Outputs
 *
 * Provides information needed to run connectivity tests.
 */

output "instance_a_public_ip" {
  value       = aws_instance.test_a.public_ip
  description = "Public IP of Test Instance A (SSH target)"
}

output "instance_a_private_ip" {
  value       = aws_instance.test_a.private_ip
  description = "Private IP of Test Instance A"
}

output "instance_b_private_ip" {
  value       = aws_instance.test_b.private_ip
  description = "Private IP of Test Instance B (ping target)"
}

output "test_instructions" {
  value = <<-EOT

    ╔══════════════════════════════════════════════════════════════════════╗
    ║                    VPC PEERING CONNECTIVITY TEST                      ║
    ╠══════════════════════════════════════════════════════════════════════╣
    ║                                                                       ║
    ║  Step 1: SSH into Test Instance A (in vpc_a)                          ║
    ║  ─────────────────────────────────────────────                        ║
    ║  ssh -i <your-key.pem> ec2-user@${aws_instance.test_a.public_ip}
    ║                                                                       ║
    ║  Step 2: Ping Test Instance B (in vpc_b)                              ║
    ║  ─────────────────────────────────────────                            ║
    ║  ping ${aws_instance.test_b.private_ip}
    ║                                                                       ║
    ║  Expected Result:                                                     ║
    ║  ────────────────                                                     ║
    ║  If VPC peering is working, you should see:                           ║
    ║  PING ${aws_instance.test_b.private_ip} 56(84) bytes of data.
    ║  64 bytes from ${aws_instance.test_b.private_ip}: icmp_seq=1 ttl=255 time=0.5 ms
    ║                                                                       ║
    ║  If peering is NOT working, you'll see:                               ║
    ║  ping: connect: Network is unreachable                                ║
    ║  (or timeout with no response)                                        ║
    ║                                                                       ║
    ╠══════════════════════════════════════════════════════════════════════╣
    ║  Instance Details:                                                    ║
    ║  • Instance A: ${aws_instance.test_a.private_ip} (vpc_a public subnet)
    ║  • Instance B: ${aws_instance.test_b.private_ip} (vpc_b private subnet)
    ╚══════════════════════════════════════════════════════════════════════╝

  EOT
  description = "Instructions for testing VPC peering connectivity"
}

output "test_summary" {
  value = {
    instance_a = {
      id         = aws_instance.test_a.id
      public_ip  = aws_instance.test_a.public_ip
      private_ip = aws_instance.test_a.private_ip
      subnet_id  = aws_instance.test_a.subnet_id
      vpc        = "vpc_a"
    }
    instance_b = {
      id         = aws_instance.test_b.id
      public_ip  = "N/A (private subnet)"
      private_ip = aws_instance.test_b.private_ip
      subnet_id  = aws_instance.test_b.subnet_id
      vpc        = "vpc_b"
    }
    test_command = "ping ${aws_instance.test_b.private_ip}"
  }
  description = "Summary of test instances"
}
