resource "aws_network_interface_sg_attachment" "attach-ec2" {
  security_group_id    = var.securitygroup_id
  network_interface_id = var.eni_id
}
