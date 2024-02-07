resource "null_resource" "ansible-copy_kubernetes_config_data2privatelearningv2" {
  depends_on = [null_resource.ansible-initialize_kubernetes_cluster]

  provisioner "file" {
    source = "${path.cwd}/software-setup/bastion_host/control_planes/_templates/ansible-copy_kubernetes_config_data2privatelearningv2.yml"
    destination = "/tmp/ansible-copy_kubernetes_config_data2privatelearningv2.yml"
  }
  provisioner "file" {
    source = "${path.cwd}/../../../../aws/aws_certified_solutions_architect/_templates/keypair/.ssh/privatelearningv2/privatelearningv2.keypair.pem"
    destination = "/tmp/privatelearningv2.keypair.pem"
  } 
  provisioner "remote-exec" {
    inline = [
      "sudo ansible-playbook /tmp/ansible-copy_kubernetes_config_data2privatelearningv2.yml -i /tmp/ansible-inventory.yml -v --ssh-common-args='-o StrictHostKeyChecking=no' > _temp2.txt",
      "grep -o -P '(?<=\"msg\": \").*(?=\")' _temp2.txt > /tmp/_tempConfigdata.txt",
      "rm _temp2.txt",

      "chmod 400 /tmp/privatelearningv2.keypair.pem",
      "ansible all -i '${var.privatelearningv2_ip},' -m copy -a 'src=/tmp/_tempConfigdata.txt dest=/home/ubuntu/Desktop/PRIVATE-LEARNINGv2/PROJECTS/learning/Cloud/kubernetes/certified_kubernetes_administrator(cka)/_learning/.kube/config force=yes' --private-key /tmp/privatelearningv2.keypair.pem -u ubuntu --ssh-common-args='-o StrictHostKeyChecking=no'"
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
