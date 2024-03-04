resource "null_resource" "rancher_installation" {
  triggers = {
    control_plane_primary_instance_id   = var.control_plane_primary_instance_id
    control_plane_secondary_instance_id = var.control_plane_secondary_instance_id
    vpc_a-region_name = var.vpc_a-region.name
  }

  provisioner "local-exec" {
    command = <<EOT
    ansible-playbook /mnt/ebs_volume/PrivateLearningV2.1/cloud-infra/kubernetes/terraform/software/ansible/install-rancher_primary.yml -e instance_id=${self.triggers.control_plane_primary_instance_id} -e region_name=${self.triggers.vpc_a-region_name}
    EOT
  }
}
