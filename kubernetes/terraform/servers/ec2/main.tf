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
  user_data            = var.user_data

  ingress-rules_map = [{
    /** CONTROL_PLANES ACCESS **/
    description = "etcd"
    protocol    = var.servers.control_planes.ports.etcd.protocol
    from_port   = tonumber(var.servers.control_planes.ports.etcd.from_port)
    to_port     = tonumber(var.servers.control_planes.ports.etcd.to_port)
    cidr_blocks = [
      "${var.vpc_a.cidr_block}"
    ]
    }, {
    description = "controller_manager & scheduler"
    protocol    = var.servers.control_planes.ports.scheduler.protocol
    from_port   = tonumber(var.servers.control_planes.ports.scheduler.from_port)
    to_port     = tonumber(var.servers.control_planes.ports.controller_manager.to_port)
    cidr_blocks = [
      "${var.vpc_a.cidr_block}"
    ]
    }, {
    /** NODES ACCESS **/
    description = "calico"
    protocol    = var.servers.control_planes.ports.calico.protocol
    from_port   = tonumber(var.servers.control_planes.ports.calico.from_port)
    to_port     = tonumber(var.servers.control_planes.ports.calico.to_port)
    cidr_blocks = [
      "${var.vpc_b.cidr_block}"
    ]
    }, {

    /** CONTROL_PLANES + NODES ACCESS **/
    description = "api_server"
    protocol    = var.servers.control_planes.ports.api_server.protocol
    from_port   = tonumber(var.servers.control_planes.ports.api_server.from_port)
    to_port     = tonumber(var.servers.control_planes.ports.api_server.to_port)
    cidr_blocks = [
      "${var.vpc_a.cidr_block}",
      "${var.vpc_b.cidr_block}"
    ]
    }, {
    description = "dns(${split("|", var.servers.control_planes.ports.dns.protocol)[0]})"
    protocol    = "${split("|", var.servers.control_planes.ports.dns.protocol)[0]}"
    from_port   = tonumber(var.servers.control_planes.ports.dns.from_port)
    to_port     = tonumber(var.servers.control_planes.ports.dns.to_port)
    cidr_blocks = [
      "${var.vpc_a.cidr_block}",
      "${var.vpc_b.cidr_block}"
    ]
    }, {
    description = "dns(${split("|", var.servers.control_planes.ports.dns.protocol)[1]})"
    protocol    = "${split("|", var.servers.control_planes.ports.dns.protocol)[1]}"
    from_port   = tonumber(var.servers.control_planes.ports.dns.from_port)
    to_port     = tonumber(var.servers.control_planes.ports.dns.to_port)
    cidr_blocks = [
      "${var.vpc_a.cidr_block}",
      "${var.vpc_b.cidr_block}"
    ]
    }, {
    /** CONTROL_PLANES + NODES + AUTHORIZED IPS ACCESS **/
    description = "kubelet"
    protocol    = var.servers.control_planes.ports.kubelet.protocol
    from_port   = tonumber(var.servers.control_planes.ports.kubelet.from_port)
    to_port     = tonumber(var.servers.control_planes.ports.kubelet.to_port)
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
  user_data            = var.user_data

  ingress-rules_map = [{
    /** CONTROL_PLANES ACCESS **/
    description = "kubelet"
    protocol    = var.servers.nodes.ports.kubelet.protocol
    from_port   = tonumber(var.servers.nodes.ports.kubelet.from_port)
    to_port     = tonumber(var.servers.nodes.ports.kubelet.to_port)
    cidr_blocks = [
      "${var.vpc_a.cidr_block}"
    ]
    }, {
    description = "calico"
    protocol    = var.servers.nodes.ports.calico.protocol
    from_port   = tonumber(var.servers.nodes.ports.calico.from_port)
    to_port     = tonumber(var.servers.nodes.ports.calico.to_port)
    cidr_blocks = [
      "${var.vpc_a.cidr_block}"
    ]
    }, {
    /** NODES ACCESS **/
    description = "flannel"
    protocol    = var.servers.nodes.ports.flannel.protocol
    from_port   = tonumber(var.servers.nodes.ports.flannel.from_port)
    to_port     = tonumber(var.servers.nodes.ports.flannel.to_port)
    cidr_blocks = [
      "${var.vpc_b.cidr_block}"
    ]
    }, {
    description = "weave (${split("|", var.servers.nodes.ports.weave.protocol)[0]})"
    protocol    = "${split("|", var.servers.nodes.ports.weave.protocol)[0]}"
    from_port   = tonumber(var.servers.nodes.ports.weave.from_port)
    to_port     = tonumber(var.servers.nodes.ports.weave.to_port)
    cidr_blocks = [
      "${var.vpc_b.cidr_block}"
    ]
    }, {
    description = "weave (${split("|", var.servers.nodes.ports.weave.protocol)[1]})"
    protocol    = "${split("|", var.servers.nodes.ports.weave.protocol)[1]}"
    from_port   = tonumber(var.servers.nodes.ports.weave.from_port)
    to_port     = tonumber(var.servers.nodes.ports.weave.to_port)
    cidr_blocks = [
      "${var.vpc_b.cidr_block}"
    ]
    }, {
    description = "calico"
    protocol    = var.servers.nodes.ports.calico.protocol
    from_port   = tonumber(var.servers.nodes.ports.calico.from_port)
    to_port     = tonumber(var.servers.nodes.ports.calico.to_port)
    cidr_blocks = [
      "${var.vpc_b.cidr_block}"
    ]
    }, {

    /** CONTROL_PLANES + NODES ACCESS **/
    description = "dns (${split("|", var.servers.nodes.ports.dns.protocol)[0]})"
    protocol    = "${split("|", var.servers.nodes.ports.dns.protocol)[0]}"
    from_port   = tonumber(var.servers.nodes.ports.dns.from_port)
    to_port     = tonumber(var.servers.nodes.ports.dns.to_port)
    cidr_blocks = [
      "${var.vpc_a.cidr_block}",
      "${var.vpc_b.cidr_block}"
    ]
    }, {
    description = "dns (${split("|", var.servers.nodes.ports.dns.protocol)[1]})"
    protocol    = "${split("|", var.servers.nodes.ports.dns.protocol)[1]}"
    from_port   = tonumber(var.servers.nodes.ports.dns.from_port)
    to_port     = tonumber(var.servers.nodes.ports.dns.to_port)
    cidr_blocks = [
      "${var.vpc_a.cidr_block}",
      "${var.vpc_b.cidr_block}"
    ]
    }, {

    /** AUTHORIZED IPS ACCESS **/
    description = "nodeport"
    protocol    = var.servers.nodes.ports.nodeport.protocol
    from_port   = tonumber(var.servers.nodes.ports.nodeport.from_port)
    to_port     = tonumber(var.servers.nodes.ports.nodeport.to_port)
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    }
  ]

}
