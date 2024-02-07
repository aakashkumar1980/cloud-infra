module "COMMON_ROOT" {
  source = "../../../certified_kubernetes_administrator(cka)"
}

module "SERVERS-CONFIGURATION" {
  source = "./servers-configuration"
  providers = {
    aws.rnvg = aws.region_nvirginia
    aws.rldn = aws.region_london
  }

  server    = local.server
  namespace = "${module.COMMON_ROOT.project.namespace}.${local.server.installation_type}"
}

resource "time_sleep" "wait_2minutess-for-server_configuration" {
  depends_on = [
    module.SERVERS-CONFIGURATION.CONTROL_PLANES,
    module.SERVERS-CONFIGURATION.NODES
  ]
  create_duration = "120s"
}
module "SOFTWARE-SETUP" {
  source     = "./software-setup"
  depends_on = [time_sleep.wait_2minutess-for-server_configuration]
  providers = {
    aws.rnvg = aws.region_nvirginia
  }

  base_namespace       = split(".", "${module.COMMON_ROOT.project.namespace}")[0]
  privatelearningv2_ip = join("",data.aws_instances.selected-privatelearningv2-aws_instance.private_ips)

  server                     = local.server
  control_planes-server1-ec2 = module.SERVERS-CONFIGURATION.output-control_planes-server1-ec2

  nodes-region_nvirginia-ec2 = module.SERVERS-CONFIGURATION.output-nodes-region_nvirginia-ec2
  nodes-region_london-ec2    = module.SERVERS-CONFIGURATION.output-nodes-region_london-ec2
}

module "DATA" {
  source = "../../../../aws/aws_certified_solutions_architect/usecases/_data"
  depends_on = [
    module.SOFTWARE-SETUP.BASTION_HOST
  ]
  providers = {
    aws.rnvg = aws.region_nvirginia
    aws.rldn = aws.region_london
  }

}
