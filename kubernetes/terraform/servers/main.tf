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
    aws = aws.region_london
  }

  ns                   = "${module.COMMON-BASE_INFRA_SETUP.project.namespace}.${module.COMMON.project.namespace}"
  vpc_c                = data.aws_vpc.vpc_c
  vpc_c-subnet_private = data.aws_subnet.vpc_c-subnet_private
  vpc_c-sg_private     = data.aws_security_group.vpc_c-sg_private

  ami                   = module.COMMON-BASE_INFRA_SETUP.project.ec2.standard.region_london.ami
  instance_type         = module.COMMON-BASE_INFRA_SETUP.project.ec2.standard.instance_type
  keypair               = "${module.COMMON-BASE_INFRA_SETUP.project.namespace}.keypair"
  iam_instance_profile  = "instance_profile-ec2_private_access"
  entity_name-primary   = local.servers.control_planes.cluster.vpc_c.primary_hostname
  entity_name-secondary = local.servers.control_planes.cluster.vpc_c.secondary_hostname

  ingress-rules_map = [{
    description = "etcd"
    protocol    = "tcp"
    from_port   = tonumber(split("-", local.servers.control_planes.ports.etcd)[0])
    to_port     = tonumber(split("-", local.servers.control_planes.ports.etcd)[1])
    cidr_blocks = [
      "${data.aws_vpc.vpc_c.cidr_block}"
    ]
    }, {
    description = "controller_manager & scheduler"
    protocol    = "tcp"
    from_port   = tonumber(local.servers.control_planes.ports.scheduler)
    to_port     = tonumber(local.servers.control_planes.ports.controller_manager)
    cidr_blocks = [
      "${data.aws_vpc.vpc_c.cidr_block}"
    ]
    }, {

    description = "api_server"
    protocol    = "tcp"
    from_port   = tonumber(local.servers.control_planes.ports.api_server)
    to_port     = tonumber(local.servers.control_planes.ports.api_server)
    cidr_blocks = [
      "${data.aws_vpc.vpc_c.cidr_block}",
      "${data.aws_vpc.vpc_a.cidr_block}", "${data.aws_vpc.vpc_b.cidr_block}"
    ]
    }, {

    description = "kubelet"
    protocol    = "tcp"
    from_port   = tonumber(local.servers.control_planes.ports.kubelet)
    to_port     = tonumber(local.servers.control_planes.ports.kubelet)
    cidr_blocks = [
      "${data.aws_vpc.vpc_c.cidr_block}",
      "${data.aws_vpc.vpc_a.cidr_block}", "${data.aws_vpc.vpc_b.cidr_block}",
      "0.0.0.0/0"
    ]
    }
  ]
}

/** NODES **/
module "NODES" {
  source = "./nodes"
  providers = {
    aws = aws.region_nvirginia
  }

  ns    = "${module.COMMON-BASE_INFRA_SETUP.project.namespace}.${module.COMMON.project.namespace}"
  cp    = local.servers.control_planes
  vpc_a = data.aws_vpc.vpc_a
  vpc_b = data.aws_vpc.vpc_b

  ingress-rules_map = [{
    description = "kubelet"
    protocol    = "tcp"
    from_port   = tonumber(local.servers.nodes.ports.kubelet)
    to_port     = tonumber(local.servers.nodes.ports.kubelet)
    cidr_blocks = [
      "${data.aws_vpc.vpc_c.cidr_block}"
    ]
    }, {
    description = "nodeport"
    protocol    = "tcp"
    from_port   = tonumber(local.servers.nodes.ports.nodeport.from_port)
    to_port     = tonumber(local.servers.nodes.ports.nodeport.to_port)
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    }
  ]

}
