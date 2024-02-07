output "output-eni" {
  value = data.aws_network_interface.selected-aws_network_interface
}
output "output-ec2" {
  value = {
    hostname   = var.hostname,
    private_ip = data.aws_instance.selected-aws_instance.private_ip
  }
}

output "output-ec2-subnet" {
  value = data.aws_subnet.selected-aws_subnet
}
