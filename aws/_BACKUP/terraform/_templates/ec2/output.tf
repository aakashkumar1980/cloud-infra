output "output-ec2" {
  value = aws_instance.ec2
}

output "output-eni" {
  value = aws_network_interface.eni
}
