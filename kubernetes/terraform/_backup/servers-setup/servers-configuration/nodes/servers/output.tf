output "output-region_nvirginia-ec2" {
  value = module.EC2-REGION_NVIRGINIA[*].output-ec2
}
output "output-region_london-ec2" {
  value = module.EC2-REGION_LONDON[*].output-ec2
}


output "output-kubelet-sg_nvirginia" {
  value = module.KUBELET_PORT_ACCESS-REGION_NVIRGINIA[*].output-sg
}
output "output-kubelet-sg_london" {
  value = module.KUBELET_PORT_ACCESS-REGION_LONDON[*].output-sg
}
output "output-kubelet-nacl_ingress_rule_nvirginia" {
  value = module.KUBELET_PORT_ACCESS-REGION_NVIRGINIA[*].output-nacl_ingress_rule
}
output "output-kubelet-nacl_ingress_rule_london" {
  value = module.KUBELET_PORT_ACCESS-REGION_LONDON[*].output-nacl_ingress_rule
}

output "output-nodeport-sg_nvirginia" {
  value = module.NODEPORT_ACCESS-REGION_NVIRGINIA[*].output-sg
}
output "output-nodeport-sg_london" {
  value = module.NODEPORT_ACCESS-REGION_LONDON[*].output-sg
}
output "output-nodeport-nacl_ingress_rule_nvirginia" {
  value = module.NODEPORT_ACCESS-REGION_NVIRGINIA[*].output-nacl_ingress_rule
}
output "output-nodeport-nacl_ingress_rule_london" {
  value = module.NODEPORT_ACCESS-REGION_LONDON[*].output-nacl_ingress_rule
}
