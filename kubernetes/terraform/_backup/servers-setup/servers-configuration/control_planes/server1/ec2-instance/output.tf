output "output-eni" {
  value = data.aws_network_interface.selected-aws_network_interface
}
output "output-ec2" {
  value = data.aws_instance.selected-aws_instance
}

output "output-ec2-subnet" {
  value = data.aws_subnet.selected-aws_subnet
}
