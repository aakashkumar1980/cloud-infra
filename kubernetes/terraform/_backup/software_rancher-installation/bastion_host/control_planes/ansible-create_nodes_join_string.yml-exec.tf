resource "null_resource" "ansible-create_nodes_join_string" {
  depends_on = [null_resource.ansible-initialize_kubernetes_cluster]

  provisioner "file" {
    source = "${path.cwd}/software-setup/bastion_host/control_planes/_templates/ansible-create_nodes_join_string.yml"
    destination = "/tmp/ansible-create_nodes_join_string.yml"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo ansible-playbook /tmp/ansible-create_nodes_join_string.yml -i /tmp/ansible-inventory.yml -v --ssh-common-args='-o StrictHostKeyChecking=no' > _temp.txt",
      "grep -o -P '(?<=\"msg\": \").*(?= \")' _temp.txt > /tmp/ansible-nodes_join_string.txt",
      "rm _temp.txt",
      "cat /tmp/ansible-nodes_join_string.txt"
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
