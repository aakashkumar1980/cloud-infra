output "vpc_ids" {
  value = { for k, v in aws_vpc.this : k => v.id }
}
