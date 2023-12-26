# expose the created resources
output "output-subnets" {
  value = aws_subnet.subnets
}
