resource "null_resource" "ansible-initialize_kubernetes_cluster" {
  depends_on = [var.null_resource_ansible-install_kubernetes]

  provisioner "file" {
    source = "${path.cwd}/software-setup/bastion_host/control_planes/_templates/ansible-initialize_kubernetes_cluster.yml"
    destination = "/tmp/ansible-initialize_kubernetes_cluster.yml"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo ansible-playbook /tmp/ansible-initialize_kubernetes_cluster.yml -i /tmp/ansible-inventory.yml -v --ssh-common-args='-o StrictHostKeyChecking=no'"
    ]
  }

  connection {
    type        = "ssh"
    user        = "centos"
    host        = join("", data.aws_instances.selected-aws_instance.public_ips)
    timeout     = "30m"
    private_key = file("${path.cwd}/../../../../aws/aws_certified_solutions_architect/_templates/keypair/.ssh/id_rsa_ec2-decrypted.pem")
  }

}
