/** hosts file **/
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

/** KUBERNETES SETUP **/
resource "null_resource" "k8s_setup" {
  depends_on = [local_file.hosts_ini]

  provisioner "local-exec" {
    command = <<EOT
      ANSIBLE_CONFIG=${path.module}/ansible/ansible.cfg \
        ansible-playbook -i ${path.module}/ansible/hosts.ini ${path.module}/k8s_setup.yml -vvv
    EOT
  }
}
