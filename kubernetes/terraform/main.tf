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
# add sleep of two minutes to allow the instances to be ready for the next steps
resource "null_resource" "sleep4minutes" {
  provisioner "local-exec" {
    command = "sleep 240"
  }
  depends_on = [module.SERVERS]
}

module "SOFTWARE" {
  source     = "./software"
  depends_on = [null_resource.sleep4minutes]
  providers = {
    aws = aws.region_nvirginia
  }

  ns      = "${module.COMMON-BASE_INFRA_SETUP.project.namespace}.${local.project.namespace}"
  base_ns = module.COMMON-BASE_INFRA_SETUP.project.namespace

  control_plane_primary_instance_id   = module.SERVERS.output-ec2_cplane_active.id
  control_plane_secondary_instance_id = module.SERVERS.output-ec2_cplane_standby.id
}

