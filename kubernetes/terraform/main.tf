module "COMMON-BASE_INFRA_SETUP" {
  source = "../../aws/terraform"
}

module "SERVERS" {
  source = "./servers"
  providers = {
    aws = aws.region_nvirginia
  }

  ns      = "${module.COMMON-BASE_INFRA_SETUP.project.namespace}.${local.project.namespace}"
  base_ns = module.COMMON-BASE_INFRA_SETUP.project.namespace

  vpc_a                = data.aws_vpc.vpc_a
  vpc_b                = data.aws_vpc.vpc_b
  vpc_a-subnet_private = data.aws_subnet.vpc_a-subnet_private
  vpc_b-subnet_private = data.aws_subnet.vpc_b-subnet_private
  vpc_a-sg_private     = data.aws_security_group.vpc_a-sg_private
  vpc_b-sg_private     = data.aws_security_group.vpc_b-sg_private

  ami           = module.COMMON-BASE_INFRA_SETUP.project.ec2.standard.region_nvirginia.ami
  keypair       = "${module.COMMON-BASE_INFRA_SETUP.project.namespace}.keypair"
  user_data_ssm = module.COMMON-BASE_INFRA_SETUP.project.ec2.standard.user_data_ssm
}
resource "null_resource" "sleep5minutes" {
  provisioner "local-exec" {
    command = "sleep 300"
  }
  depends_on = [module.SERVERS]
}


module "SOFTWARE" {
  source = "./software"
  depends_on = [null_resource.sleep5minutes]
  providers = {
    aws = aws.region_nvirginia
  }

  ns      = "${module.COMMON-BASE_INFRA_SETUP.project.namespace}.${local.project.namespace}"
  base_ns = module.COMMON-BASE_INFRA_SETUP.project.namespace

  vpc_a-region_name                         = data.aws_region.vpc_a-region.name
  vpc_b-region_name                         = data.aws_region.vpc_b-region.name
  control_plane_primary_instance_id         = module.SERVERS.output-ec2_cplane_active.id
  control_plane_primary_instance_private_ip = module.SERVERS.output-ec2_cplane_active.private_ip
  node1_instance_id                         = module.SERVERS.output-ec2_node1.id
  node1_instance_private_ip                 = module.SERVERS.output-ec2_node1.private_ip
  node2_instance_id                         = module.SERVERS.output-ec2_node2.id
  node2_instance_private_ip                 = module.SERVERS.output-ec2_node2.private_ip
}
