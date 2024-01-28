module "COMMON-BASE_INFRA_SETUP" {
  source = "../../../aws/terraform"
}
module "COMMON" {
  source = "../../terraform"
}


/** CONTROL_PLANES **/
module "CONTROL_PLANES" {
  source = "./control_planes"
  providers = {
    aws.rgn_nvg = aws.region_nvirginia
    aws.rgn_ldn = aws.region_london
  }

  ns                 = "${module.COMMON-BASE_INFRA_SETUP.project.namespace}.${module.COMMON.project.namespace}"
  cp                 = local.servers.control_planes
  vpc_a              = data.aws_vpc.vpc_a
  vpc_b              = data.aws_vpc.vpc_b
  vpc_c              = data.aws_vpc.vpc_c
  vpc_a-nacl_private = data.aws_network_acls.vpc_a-nacl_private
  vpc_b-nacl_private = data.aws_network_acls.vpc_b-nacl_private
  vpc_c-nacl_private = data.aws_network_acls.vpc_c-nacl_private

  ingress-rules_map = [{
    description = "etcd"
    protocol    = "tcp"
    from_port   = tonumber(split("-", local.servers.control_planes.ports.etcd)[0])
    to_port     = tonumber(split("-", local.servers.control_planes.ports.etcd)[1])
    cidr_blocks = ["${data.aws_vpc.vpc_b.cidr_block}", "${data.aws_vpc.vpc_c.cidr_block}"]
    }, {
    description = "controller_manager"
    protocol    = "tcp"
    from_port   = tonumber(local.servers.control_planes.ports.controller_manager)
    to_port     = tonumber(local.servers.control_planes.ports.controller_manager)
    cidr_blocks = ["${data.aws_vpc.vpc_b.cidr_block}", "${data.aws_vpc.vpc_c.cidr_block}"]
    }, {
    description = "scheduler"
    protocol    = "tcp"
    from_port   = tonumber(local.servers.control_planes.ports.scheduler)
    to_port     = tonumber(local.servers.control_planes.ports.scheduler)
    cidr_blocks = ["${data.aws_vpc.vpc_b.cidr_block}", "${data.aws_vpc.vpc_c.cidr_block}"]
    }, {

    description = "api_server"
    protocol    = "tcp"
    from_port   = tonumber(local.servers.control_planes.ports.api_server)
    to_port     = tonumber(local.servers.control_planes.ports.api_server)
    cidr_blocks = [
      "${data.aws_vpc.vpc_b.cidr_block}",
      "${data.aws_vpc.vpc_c.cidr_block}",
      "${data.aws_vpc.vpc_a.cidr_block}"
    ]
    }, {

    description = "kubelet"
    protocol    = "tcp"
    from_port   = tonumber(local.servers.control_planes.ports.kubelet)
    to_port     = tonumber(local.servers.control_planes.ports.kubelet)
    cidr_blocks = [
      "${data.aws_vpc.vpc_b.cidr_block}",
      "${data.aws_vpc.vpc_c.cidr_block}",
      "${data.aws_vpc.vpc_a.cidr_block}"
    ]
    }
  ]

}
