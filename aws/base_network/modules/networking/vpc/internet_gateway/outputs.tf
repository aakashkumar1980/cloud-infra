# Internet Gateway IDs (map of vpc_name => igw_id)
output "igw_ids" {
  value = { for k, v in aws_internet_gateway.this : k => v.id }
}

# Internet Gateway names (map of vpc_name => igw_name)
output "igw_names" {
  value = { for k, v in aws_internet_gateway.this : k => v.tags["Name"] }
}
