module "SOFTWARE_COMMON" {
  source = "./common"

  tagname = var.tagname
  server1 = var.server1
  nodes   = var.nodes
  keypair = var.keypair
}


module "CONTROL_PLANES" {
  source = "./control_planes"
  depends_on = [
    module.SOFTWARE_COMMON
  ]

  tagname                                  = var.tagname
  privatelearningv2_ip                     = var.privatelearningv2_ip
  null_resource_ansible-install_kubernetes = module.SOFTWARE_COMMON.output-null_resource_ansible-install_kubernetes
}
module "NODES" {
  source = "./nodes"
  depends_on = [
    module.CONTROL_PLANES
  ]

  tagname                                        = var.tagname
  null_resource_ansible-create_nodes_join_string = module.CONTROL_PLANES.output-null_resource_ansible-create_nodes_join_string
}

