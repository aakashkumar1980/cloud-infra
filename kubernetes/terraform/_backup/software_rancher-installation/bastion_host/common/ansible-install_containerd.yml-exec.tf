resource "time_sleep" "wait_5minutes-for-change_hostname" {
  depends_on = [null_resource.ansible-change_hostname]
  create_duration = "300s"
}

resource "null_resource" "ansible-install_containerd" {
  depends_on = [time_sleep.wait_5minutes-for-change_hostname]

  provisioner "file" {
    source = "${path.cwd}/software-setup/bastion_host/common/_templates/ansible-install_containerd.yml"
    destination = "/tmp/ansible-install_containerd.yml"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo ansible-playbook /tmp/ansible-install_containerd.yml -i /tmp/ansible-inventory.yml -v --ssh-common-args='-o StrictHostKeyChecking=no'"
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
