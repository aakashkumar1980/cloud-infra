output "output-control_planes-server1-eni" {
  value = module.CONTROL_PLANES.output-server1-eni
}
output "output-control_planes-server1-ec2" {
  value = module.CONTROL_PLANES.output-server1-ec2
}
output "output-control_planes-server1-ec2-subnet" {
  value = module.CONTROL_PLANES.output-server1-ec2-subnet
}
output "output-control_planes-server1-sg" {
  value = module.CONTROL_PLANES.output-server1-sg
}
output "output-control_planes-server1-nacl_ingress_rule" {
  value = module.CONTROL_PLANES.output-server1-nacl_ingress_rule
}


output "output-nodes-region_nvirginia-ec2" {
  value = module.NODES.output-region_nvirginia-ec2
}
output "output-nodes-region_london-ec2" {
  value = module.NODES.output-region_london-ec2
}


output "output-nodes-kubelet-sg_nvirginia" {
  value = module.NODES.output-servers-kubelet-sg_nvirginia
}
output "output-nodes-kubelet-sg_london" {
  value = module.NODES.output-servers-kubelet-sg_london
}
output "output-nodes-kubelet-nacl_ingress_rule_nvirginia" {
  value = module.NODES.output-servers-kubelet-nacl_ingress_rule_nvirginia
}
output "output-nodes-kubelet-nacl_ingress_rule_london" {
  value = module.NODES.output-servers-kubelet-nacl_ingress_rule_london
}

output "output-nodes-nodeport-sg_nvirginia" {
  value = module.NODES.output-servers-nodeport-sg_nvirginia
}
output "output-nodes-nodeport-sg_london" {
  value = module.NODES.output-servers-nodeport-sg_london
}
output "output-nodes-nodeport-nacl_ingress_rule_nvirginia" {
  value = module.NODES.output-servers-nodeport-nacl_ingress_rule_nvirginia
}
output "output-nodes-nodeport-nacl_ingress_rule_london" {
  value = module.NODES.output-servers-nodeport-nacl_ingress_rule_london
}