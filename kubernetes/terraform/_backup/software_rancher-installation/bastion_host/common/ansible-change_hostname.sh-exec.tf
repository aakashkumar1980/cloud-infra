resource "null_resource" "ansible-change_hostname" {
  depends_on = [null_resource.ansible-inventory]

  provisioner "file" {
    content = templatefile(
      "${path.cwd}/software-setup/bastion_host/common/_templates/ansible-change_hostnames.yml.tpl",
      {}
    )
    destination = "/tmp/ansible-change_hostnames.yml"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo ansible-playbook /tmp/ansible-change_hostnames.yml -i /tmp/ansible-inventory.yml -vv --ssh-common-args='-o StrictHostKeyChecking=no'"
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
