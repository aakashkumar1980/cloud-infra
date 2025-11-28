# NAT Gateway IDs (used by private route tables)
output "nat_gateway_ids" {
  value       = { for k, v in aws_nat_gateway.this : k => v.id }
  description = "Map of VPC names to NAT Gateway IDs"
}

# NAT Gateway public IPs
output "nat_gateway_public_ips" {
  value       = { for k, v in aws_nat_gateway.this : k => v.public_ip }
  description = "Map of VPC names to NAT Gateway public IPs"
}

# NAT Gateway names with IGW relationship
output "nat_gateway_names" {
  value       = { for k, v in aws_nat_gateway.this : k => "${v.tags["Name"]} -> ${var.igw_names[k]}" }
  description = "Map of VPC names to NAT Gateway names"
}

# Elastic IP allocation IDs
output "eip_allocation_ids" {
  value       = { for k, v in aws_eip.nat : k => v.id }
  description = "Map of VPC names to EIP allocation IDs"
}
