output "output-ec2_cplane_active" {
  value = module.EC2["cplane_active"].output-ec2
}

output "output-ec2_cplane_standby" {
  value = module.EC2["cplane_standby"].output-ec2
}
