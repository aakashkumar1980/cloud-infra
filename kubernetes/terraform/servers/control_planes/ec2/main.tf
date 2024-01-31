module "EC2_PRIMARY" {
  source = "../../../../../aws/terraform/_templates/ec2"

  subnet_id       = var.vpc_c-subnet_private.id
  security_groups = var.security_group_ids
  user_data       = <<-EOF
    #!/bin/bash

    # Install the Amazon SSM Agent
    sudo dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

    # Enable and start the SSM Agent service
    sudo systemctl enable amazon-ssm-agent
    sudo systemctl start amazon-ssm-agent
    EOF  

  ami                  = var.ami
  instance_type        = var.instance_type
  keypair              = var.keypair
  iam_instance_profile = var.iam_instance_profile

  tag_path    = var.tag_path
  entity_name = var.entity_name-primary
}
module "EC2_SECONDARY" {
  source = "../../../../../aws/terraform/_templates/ec2"

  subnet_id       = var.vpc_c-subnet_private.id
  security_groups = var.security_group_ids
  user_data       = <<-EOF
    #!/bin/bash

    # Install the Amazon SSM Agent
    sudo dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

    # Enable and start the SSM Agent service
    sudo systemctl enable amazon-ssm-agent
    sudo systemctl start amazon-ssm-agent
    EOF  

  ami                  = var.ami
  instance_type        = var.instance_type
  keypair              = var.keypair
  iam_instance_profile = var.iam_instance_profile

  tag_path    = var.tag_path
  entity_name = var.entity_name-secondary
}
