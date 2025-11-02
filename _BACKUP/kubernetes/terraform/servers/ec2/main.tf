/** CONTROL_PLANES **/
module "CONTROL_PLANES" {
  source = "./control_planes"

  ns                   = var.ns
  base_ns              = var.base_ns
  cluster              = var.servers.control_planes.cluster
  vpc_a                = var.vpc_a
  vpc_b                = var.vpc_b
  vpc_a-subnet_private = var.vpc_a-subnet_private
  vpc_b-subnet_private = var.vpc_b-subnet_private
  vpc_a-sg_private     = var.vpc_a-sg_private
  vpc_b-sg_private     = var.vpc_b-sg_private

  ami                  = var.ami
  instance_type        = var.servers.control_planes.instance_type
  keypair              = var.keypair
  iam_instance_profile = resource.aws_iam_instance_profile.instance_profile-ec2.name
  user_data_ssm        = var.user_data_ssm

  /** EFS ACCESS **/
  /**
  user_data_efs   = local.user_data_efs
  efs-output-sg   = var.efs-output-sg
  efs-ingress-rules_map = [{
    description = "efs"
    protocol    = var.efs.vpc_a.security_group.ingress.protocol
    from_port   = tonumber(var.efs.vpc_a.security_group.ingress.from_port)
    to_port     = tonumber(var.efs.vpc_a.security_group.ingress.to_port)
  }]
  **/

  ingress-rules_map = [{
    /** CONTROL_PLANES ACCESS **/
    description = "etcd"
    protocol    = var.servers.control_planes.securitygroup.ingress.etcd.protocol
    from_port   = tonumber(var.servers.control_planes.securitygroup.ingress.etcd.from_port)
    to_port     = tonumber(var.servers.control_planes.securitygroup.ingress.etcd.to_port)
    cidr_blocks = [
      "${var.vpc_a.cidr_block}"
    ]
    }, {
    description = "controller_manager & scheduler"
    protocol    = var.servers.control_planes.securitygroup.ingress.scheduler.protocol
    from_port   = tonumber(var.servers.control_planes.securitygroup.ingress.scheduler.from_port)
    to_port     = tonumber(var.servers.control_planes.securitygroup.ingress.controller_manager.to_port)
    cidr_blocks = [
      "${var.vpc_a.cidr_block}"
    ]
    }, {
    /** NODES ACCESS **/
    description = "calico"
    protocol    = var.servers.control_planes.securitygroup.ingress.calico.protocol
    from_port   = tonumber(var.servers.control_planes.securitygroup.ingress.calico.from_port)
    to_port     = tonumber(var.servers.control_planes.securitygroup.ingress.calico.to_port)
    cidr_blocks = [
      "${var.vpc_b.cidr_block}"
    ]
    }, {

    /** CONTROL_PLANES + NODES ACCESS **/
    description = "api_server"
    protocol    = var.servers.control_planes.securitygroup.ingress.api_server.protocol
    from_port   = tonumber(var.servers.control_planes.securitygroup.ingress.api_server.from_port)
    to_port     = tonumber(var.servers.control_planes.securitygroup.ingress.api_server.to_port)
    cidr_blocks = [
      "${var.vpc_a.cidr_block}",
      "${var.vpc_b.cidr_block}"
    ]
    }, {
    description = "dns(${split("|", var.servers.control_planes.securitygroup.ingress.dns.protocol)[0]})"
    protocol    = "${split("|", var.servers.control_planes.securitygroup.ingress.dns.protocol)[0]}"
    from_port   = tonumber(var.servers.control_planes.securitygroup.ingress.dns.from_port)
    to_port     = tonumber(var.servers.control_planes.securitygroup.ingress.dns.to_port)
    cidr_blocks = [
      "${var.vpc_a.cidr_block}",
      "${var.vpc_b.cidr_block}"
    ]
    }, {
    description = "dns(${split("|", var.servers.control_planes.securitygroup.ingress.dns.protocol)[1]})"
    protocol    = "${split("|", var.servers.control_planes.securitygroup.ingress.dns.protocol)[1]}"
    from_port   = tonumber(var.servers.control_planes.securitygroup.ingress.dns.from_port)
    to_port     = tonumber(var.servers.control_planes.securitygroup.ingress.dns.to_port)
    cidr_blocks = [
      "${var.vpc_a.cidr_block}",
      "${var.vpc_b.cidr_block}"
    ]
    }, {
    /** CONTROL_PLANES + NODES + AUTHORIZED IPS ACCESS **/
    description = "kubelet"
    protocol    = var.servers.control_planes.securitygroup.ingress.kubelet.protocol
    from_port   = tonumber(var.servers.control_planes.securitygroup.ingress.kubelet.from_port)
    to_port     = tonumber(var.servers.control_planes.securitygroup.ingress.kubelet.to_port)
    cidr_blocks = [
      "${var.vpc_a.cidr_block}",
      "${var.vpc_b.cidr_block}",
      "0.0.0.0/0"
    ]
    }
  ]
}

/** NODES **/
module "NODES" {
  source = "./nodes"

  ns                   = var.ns
  base_ns              = var.base_ns
  cluster              = var.servers.nodes.cluster
  vpc_a                = var.vpc_a
  vpc_b                = var.vpc_b
  vpc_a-subnet_private = var.vpc_a-subnet_private
  vpc_b-subnet_private = var.vpc_b-subnet_private
  vpc_a-sg_private     = var.vpc_a-sg_private
  vpc_b-sg_private     = var.vpc_b-sg_private

  ami                  = var.ami
  instance_type        = var.servers.nodes.instance_type
  keypair              = var.keypair
  iam_instance_profile = resource.aws_iam_instance_profile.instance_profile-ec2.name
  user_data_ssm        = var.user_data_ssm

  /** EFS ACCESS **/
  /**
  user_data_efs   = local.user_data_efs
  efs-output-sg   = var.efs-output-sg
  efs-ingress-rules_map = [{
    description = "efs"
    protocol    = var.efs.vpc_a.security_group.ingress.protocol
    from_port   = tonumber(var.efs.vpc_a.security_group.ingress.from_port)
    to_port     = tonumber(var.efs.vpc_a.security_group.ingress.to_port)
  }]
  **/

  ingress-rules_map = [{
    /** CONTROL_PLANES ACCESS **/
    description = "kubelet"
    protocol    = var.servers.nodes.securitygroup.ingress.kubelet.protocol
    from_port   = tonumber(var.servers.nodes.securitygroup.ingress.kubelet.from_port)
    to_port     = tonumber(var.servers.nodes.securitygroup.ingress.kubelet.to_port)
    cidr_blocks = [
      "${var.vpc_a.cidr_block}"
    ]
    }, {
    description = "calico"
    protocol    = var.servers.nodes.securitygroup.ingress.calico.protocol
    from_port   = tonumber(var.servers.nodes.securitygroup.ingress.calico.from_port)
    to_port     = tonumber(var.servers.nodes.securitygroup.ingress.calico.to_port)
    cidr_blocks = [
      "${var.vpc_a.cidr_block}"
    ]
    }, {
    /** NODES ACCESS **/
    description = "flannel"
    protocol    = var.servers.nodes.securitygroup.ingress.flannel.protocol
    from_port   = tonumber(var.servers.nodes.securitygroup.ingress.flannel.from_port)
    to_port     = tonumber(var.servers.nodes.securitygroup.ingress.flannel.to_port)
    cidr_blocks = [
      "${var.vpc_b.cidr_block}"
    ]
    }, {
    description = "weave (${split("|", var.servers.nodes.securitygroup.ingress.weave.protocol)[0]})"
    protocol    = "${split("|", var.servers.nodes.securitygroup.ingress.weave.protocol)[0]}"
    from_port   = tonumber(var.servers.nodes.securitygroup.ingress.weave.from_port)
    to_port     = tonumber(var.servers.nodes.securitygroup.ingress.weave.to_port)
    cidr_blocks = [
      "${var.vpc_b.cidr_block}"
    ]
    }, {
    description = "weave (${split("|", var.servers.nodes.securitygroup.ingress.weave.protocol)[1]})"
    protocol    = "${split("|", var.servers.nodes.securitygroup.ingress.weave.protocol)[1]}"
    from_port   = tonumber(var.servers.nodes.securitygroup.ingress.weave.from_port)
    to_port     = tonumber(var.servers.nodes.securitygroup.ingress.weave.to_port)
    cidr_blocks = [
      "${var.vpc_b.cidr_block}"
    ]
    }, {
    description = "calico"
    protocol    = var.servers.nodes.securitygroup.ingress.calico.protocol
    from_port   = tonumber(var.servers.nodes.securitygroup.ingress.calico.from_port)
    to_port     = tonumber(var.servers.nodes.securitygroup.ingress.calico.to_port)
    cidr_blocks = [
      "${var.vpc_b.cidr_block}"
    ]
    }, {

    /** CONTROL_PLANES + NODES ACCESS **/
    description = "dns (${split("|", var.servers.nodes.securitygroup.ingress.dns.protocol)[0]})"
    protocol    = "${split("|", var.servers.nodes.securitygroup.ingress.dns.protocol)[0]}"
    from_port   = tonumber(var.servers.nodes.securitygroup.ingress.dns.from_port)
    to_port     = tonumber(var.servers.nodes.securitygroup.ingress.dns.to_port)
    cidr_blocks = [
      "${var.vpc_a.cidr_block}",
      "${var.vpc_b.cidr_block}"
    ]
    }, {
    description = "dns (${split("|", var.servers.nodes.securitygroup.ingress.dns.protocol)[1]})"
    protocol    = "${split("|", var.servers.nodes.securitygroup.ingress.dns.protocol)[1]}"
    from_port   = tonumber(var.servers.nodes.securitygroup.ingress.dns.from_port)
    to_port     = tonumber(var.servers.nodes.securitygroup.ingress.dns.to_port)
    cidr_blocks = [
      "${var.vpc_a.cidr_block}",
      "${var.vpc_b.cidr_block}"
    ]
    }, {

    /** AUTHORIZED IPS ACCESS **/
    description = "nodeport"
    protocol    = var.servers.nodes.securitygroup.ingress.nodeport.protocol
    from_port   = tonumber(var.servers.nodes.securitygroup.ingress.nodeport.from_port)
    to_port     = tonumber(var.servers.nodes.securitygroup.ingress.nodeport.to_port)
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    }
  ]

}
