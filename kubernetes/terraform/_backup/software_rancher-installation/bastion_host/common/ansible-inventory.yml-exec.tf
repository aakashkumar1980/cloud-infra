resource "null_resource" "ansible-inventory" {
  provisioner "file" {
    content = templatefile(
      "${path.cwd}/software-setup/bastion_host/common/_templates/ansible-inventory.yml.tpl",
      { server1 = "${var.server1}", nodes = "${var.nodes}", keypair = var.keypair }
    )
    destination = "/tmp/ansible-inventory.yml"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum install epel-release -y",
      "sudo yum install ansible -y"

      /** NOTE: Test by connecting manually to the Bastion_Host server
      $ sudo ansible -i /tmp/ansible-inventory.yml kubernetes_cluster -m ping --ssh-common-args='-o StrictHostKeyChecking=no'
      **/
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
