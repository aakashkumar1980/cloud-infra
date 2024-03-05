data "template_file" "hosts" {
  template = file("${path.module}/ansible/hosts.tpl")

  vars = {
    control_plane_primary_instance_private_ip = var.control_plane_primary_instance_private_ip
    node1_instance_private_ip                 = var.node1_instance_private_ip
    node2_instance_private_ip                 = var.node2_instance_private_ip
  }
}
resource "local_file" "hosts_ini" {
  content  = data.template_file.hosts.rendered
  filename = "${path.module}/ansible/hosts.ini"
}


resource "null_resource" "terraform_installation" {
  depends_on = [local_file.hosts_ini]
  triggers = {
    control_plane_primary_instance_id         = var.control_plane_primary_instance_id
    control_plane_primary_instance_private_ip = var.control_plane_primary_instance_private_ip
    node1_instance_id                         = var.node1_instance_id
    node1_instance_private_ip                 = var.node1_instance_private_ip
    node2_instance_id                         = var.node2_instance_id
    node2_instance_private_ip                 = var.node2_instance_private_ip
    vpc_a-region_name                         = var.vpc_a-region_name
  }

  provisioner "local-exec" {
    command = <<EOT
      ansible-playbook -i ${path.module}/ansible/hosts.ini ${path.module}/ansible/install_kubernetes.yml  \
        --extra-vars \
        "control_plane_primary_instance_id='${var.control_plane_primary_instance_id}' \
        control_plane_primary_instance_private_ip='${var.control_plane_primary_instance_private_ip}' \
        node1_instance_id='${var.node1_instance_id}' \
        node1_instance_private_ip='${var.node1_instance_private_ip}' \
        node2_instance_id='${var.node2_instance_id}' \
        node2_instance_private_ip='${var.node2_instance_private_ip}' \
        region_name=${var.vpc_a-region_name}" -vvv \
    EOT
  }
}
