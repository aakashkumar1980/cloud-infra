resource "null_resource" "ansible-join_nodes" {
  depends_on = [var.null_resource_ansible-create_nodes_join_string]

  provisioner "file" {
    source = "${path.cwd}/software-setup/bastion_host/nodes/_templates/ansible-join_nodes.yml"
    destination = "/tmp/ansible-join_nodes.yml"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo ansible-playbook /tmp/ansible-join_nodes.yml --extra-vars \"node_join_string='$(cat /tmp/ansible-nodes_join_string.txt)'\"  -i /tmp/ansible-inventory.yml -v --ssh-common-args='-o StrictHostKeyChecking=no'"
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
