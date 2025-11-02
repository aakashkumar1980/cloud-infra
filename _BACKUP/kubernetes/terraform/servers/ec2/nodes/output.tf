output "output-ec2_node1" {
  value = module.EC2["0"].output-ec2
}
output "output-ec2_node2" {
  value = module.EC2["1"].output-ec2
}
