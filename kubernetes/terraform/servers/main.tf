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
    aws = aws.region_nvirginia
  }

  ns                   = "${module.COMMON-BASE_INFRA_SETUP.project.namespace}.${module.COMMON.project.namespace}"
  cluster              = local.servers.control_planes.cluster
  vpc_a                = data.aws_vpc.vpc_a
  vpc_b                = data.aws_vpc.vpc_b
  vpc_a-subnet_private = data.aws_subnet.vpc_a-subnet_private
  vpc_b-subnet_private = data.aws_subnet.vpc_b-subnet_private
  vpc_a-sg_private     = data.aws_security_group.vpc_a-sg_private
  vpc_b-sg_private     = data.aws_security_group.vpc_b-sg_private

  ami                  = module.COMMON-BASE_INFRA_SETUP.project.ec2.standard.region_nvirginia.ami
  instance_type        = local.servers.control_planes.instance_type
  keypair              = "${module.COMMON-BASE_INFRA_SETUP.project.namespace}.keypair"
  iam_instance_profile = resource.aws_iam_instance_profile.instance_profile-ec2.name
  user_data            = module.COMMON-BASE_INFRA_SETUP.project.ec2.standard.user_data

  ingress-rules_map = [{
    /** CONTROL_PLANES ACCESS **/
    description = "etcd"
    protocol    = local.servers.control_planes.ports.etcd.protocol
    from_port   = tonumber(local.servers.control_planes.ports.etcd.from_port)
    to_port     = tonumber(local.servers.control_planes.ports.etcd.to_port)
    cidr_blocks = [
      "${data.aws_vpc.vpc_a.cidr_block}"
    ]
    }, {
    description = "controller_manager & scheduler"
    protocol    = local.servers.control_planes.ports.scheduler.protocol
    from_port   = tonumber(local.servers.control_planes.ports.scheduler.from_port)
    to_port     = tonumber(local.servers.control_planes.ports.controller_manager.to_port)
    cidr_blocks = [
      "${data.aws_vpc.vpc_a.cidr_block}"
    ]
    }, {
    /** NODES ACCESS **/
    description = "calico"
    protocol    = local.servers.control_planes.ports.calico.protocol
    from_port   = tonumber(local.servers.control_planes.ports.calico.from_port)
    to_port     = tonumber(local.servers.control_planes.ports.calico.to_port)
    cidr_blocks = [
      "${data.aws_vpc.vpc_b.cidr_block}"
    ]
    }, {

    /** CONTROL_PLANES + NODES ACCESS **/
    description = "api_server"
    protocol    = local.servers.control_planes.ports.api_server.protocol
    from_port   = tonumber(local.servers.control_planes.ports.api_server.from_port)
    to_port     = tonumber(local.servers.control_planes.ports.api_server.to_port)
    cidr_blocks = [
      "${data.aws_vpc.vpc_a.cidr_block}",
      "${data.aws_vpc.vpc_b.cidr_block}"
    ]
    }, {
    description = "dns(${split("|", local.servers.control_planes.ports.dns.protocol)[0]})"
    protocol    = "${split("|", local.servers.control_planes.ports.dns.protocol)[0]}"
    from_port   = tonumber(local.servers.control_planes.ports.dns.from_port)
    to_port     = tonumber(local.servers.control_planes.ports.dns.to_port)
    cidr_blocks = [
      "${data.aws_vpc.vpc_a.cidr_block}",
      "${data.aws_vpc.vpc_b.cidr_block}"
    ]
    }, {
    description = "dns(${split("|", local.servers.control_planes.ports.dns.protocol)[1]})"
    protocol    = "${split("|", local.servers.control_planes.ports.dns.protocol)[1]}"
    from_port   = tonumber(local.servers.control_planes.ports.dns.from_port)
    to_port     = tonumber(local.servers.control_planes.ports.dns.to_port)
    cidr_blocks = [
      "${data.aws_vpc.vpc_a.cidr_block}",
      "${data.aws_vpc.vpc_b.cidr_block}"
    ]
    }, {
    /** CONTROL_PLANES + NODES + AUTHORIZED IPS ACCESS **/
    description = "kubelet"
    protocol    = local.servers.control_planes.ports.kubelet.protocol
    from_port   = tonumber(local.servers.control_planes.ports.kubelet.from_port)
    to_port     = tonumber(local.servers.control_planes.ports.kubelet.to_port)
    cidr_blocks = [
      "${data.aws_vpc.vpc_a.cidr_block}",
      "${data.aws_vpc.vpc_b.cidr_block}",
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

  ns                   = "${module.COMMON-BASE_INFRA_SETUP.project.namespace}.${module.COMMON.project.namespace}"
  vpc_b-cluster        = local.servers.nodes.cluster.vpc_b
  vpc_a                = data.aws_vpc.vpc_a
  vpc_b                = data.aws_vpc.vpc_b
  vpc_a-subnet_private = data.aws_subnet.vpc_a-subnet_private
  vpc_b-subnet_private = data.aws_subnet.vpc_b-subnet_private
  vpc_a-sg_private     = data.aws_security_group.vpc_a-sg_private
  vpc_b-sg_private     = data.aws_security_group.vpc_b-sg_private

  ami                  = module.COMMON-BASE_INFRA_SETUP.project.ec2.standard.region_nvirginia.ami
  instance_type        = local.servers.nodes.instance_type
  keypair              = "${module.COMMON-BASE_INFRA_SETUP.project.namespace}.keypair"
  iam_instance_profile = resource.aws_iam_instance_profile.instance_profile-ec2.name
  user_data            = module.COMMON-BASE_INFRA_SETUP.project.ec2.standard.user_data

  ingress-rules_map = [{
    /** CONTROL_PLANES ACCESS **/
    description = "kubelet"
    protocol    = local.servers.nodes.ports.kubelet.protocol
    from_port   = tonumber(local.servers.nodes.ports.kubelet.from_port)
    to_port     = tonumber(local.servers.nodes.ports.kubelet.to_port)
    cidr_blocks = [
      "${data.aws_vpc.vpc_a.cidr_block}"
    ]
    }, {
    description = "calico"
    protocol    = local.servers.nodes.ports.calico.protocol
    from_port   = tonumber(local.servers.nodes.ports.calico.from_port)
    to_port     = tonumber(local.servers.nodes.ports.calico.to_port)
    cidr_blocks = [
      "${data.aws_vpc.vpc_a.cidr_block}"
    ]
    }, {
    /** NODES ACCESS **/
    description = "flannel"
    protocol    = local.servers.nodes.ports.flannel.protocol
    from_port   = tonumber(local.servers.nodes.ports.flannel.from_port)
    to_port     = tonumber(local.servers.nodes.ports.flannel.to_port)
    cidr_blocks = [
      "${data.aws_vpc.vpc_b.cidr_block}"
    ]
    }, {
    description = "weave (${split("|", local.servers.nodes.ports.weave.protocol)[0]})"
    protocol    = "${split("|", local.servers.nodes.ports.weave.protocol)[0]}"
    from_port   = tonumber(local.servers.nodes.ports.weave.from_port)
    to_port     = tonumber(local.servers.nodes.ports.weave.to_port)
    cidr_blocks = [
      "${data.aws_vpc.vpc_b.cidr_block}"
    ]
    }, {
    description = "weave (${split("|", local.servers.nodes.ports.weave.protocol)[1]})"
    protocol    = "${split("|", local.servers.nodes.ports.weave.protocol)[1]}"
    from_port   = tonumber(local.servers.nodes.ports.weave.from_port)
    to_port     = tonumber(local.servers.nodes.ports.weave.to_port)
    cidr_blocks = [
      "${data.aws_vpc.vpc_b.cidr_block}"
    ]
    }, {
    description = "calico"
    protocol    = local.servers.nodes.ports.calico.protocol
    from_port   = tonumber(local.servers.nodes.ports.calico.from_port)
    to_port     = tonumber(local.servers.nodes.ports.calico.to_port)
    cidr_blocks = [
      "${data.aws_vpc.vpc_b.cidr_block}"
    ]
    }, {

    /** CONTROL_PLANES + NODES ACCESS **/
    description = "dns (${split("|", local.servers.nodes.ports.dns.protocol)[0]})"
    protocol    = "${split("|", local.servers.nodes.ports.dns.protocol)[0]}"
    from_port   = tonumber(local.servers.nodes.ports.dns.from_port)
    to_port     = tonumber(local.servers.nodes.ports.dns.to_port)
    cidr_blocks = [
      "${data.aws_vpc.vpc_a.cidr_block}",
      "${data.aws_vpc.vpc_b.cidr_block}"
    ]
    }, {
    description = "dns (${split("|", local.servers.nodes.ports.dns.protocol)[1]})"
    protocol    = "${split("|", local.servers.nodes.ports.dns.protocol)[1]}"
    from_port   = tonumber(local.servers.nodes.ports.dns.from_port)
    to_port     = tonumber(local.servers.nodes.ports.dns.to_port)
    cidr_blocks = [
      "${data.aws_vpc.vpc_a.cidr_block}",
      "${data.aws_vpc.vpc_b.cidr_block}"
    ]
    }, {

    /** AUTHORIZED IPS ACCESS **/
    description = "nodeport"
    protocol    = local.servers.nodes.ports.nodeport.protocol
    from_port   = tonumber(local.servers.nodes.ports.nodeport.from_port)
    to_port     = tonumber(local.servers.nodes.ports.nodeport.to_port)
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    }
  ]

}
