output "output-region_nvirginia-ec2" {
  value = module.SERVERS.output-region_nvirginia-ec2
}
output "output-region_london-ec2" {
  value = module.SERVERS.output-region_london-ec2
}


output "output-servers-kubelet-sg_nvirginia" {
  value = module.SERVERS.output-kubelet-sg_nvirginia
}
output "output-servers-kubelet-sg_london" {
  value = module.SERVERS.output-kubelet-sg_london
}
output "output-servers-kubelet-nacl_ingress_rule_nvirginia" {
  value = module.SERVERS.output-kubelet-nacl_ingress_rule_nvirginia
}
output "output-servers-kubelet-nacl_ingress_rule_london" {
  value = module.SERVERS.output-kubelet-nacl_ingress_rule_london
}

output "output-servers-nodeport-sg_nvirginia" {
  value = module.SERVERS.output-nodeport-sg_nvirginia
}
output "output-servers-nodeport-sg_london" {
  value = module.SERVERS.output-nodeport-sg_london
}
output "output-servers-nodeport-nacl_ingress_rule_nvirginia" {
  value = module.SERVERS.output-nodeport-nacl_ingress_rule_nvirginia
}
output "output-servers-nodeport-nacl_ingress_rule_london" {
  value = module.SERVERS.output-nodeport-nacl_ingress_rule_london
}