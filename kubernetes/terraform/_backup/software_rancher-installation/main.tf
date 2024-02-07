/** KUBERNETES SOFTWARE SETUP via. Bastion Host Server **/
module "BASTION_HOST" {
  source = "./bastion_host"
  providers = {
    aws = aws.rnvg
  }

  tagname              = var.server.bastion_host.tagname
  privatelearningv2_ip = var.privatelearningv2_ip

  # ansible: inventory
  server1 = {
    hostname   = var.server.control_planes.server1.hostname,
    private_ip = var.control_planes-server1-ec2.private_ip
  }
  nodes = flatten(concat(
    [var.nodes-region_nvirginia-ec2],
    [var.nodes-region_london-ec2]
  ))

  keypair = "${var.base_namespace}.keypair.pem"
}

