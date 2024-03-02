resource "aws_ssm_document" "install_docker" {
  name          = "install-docker-centos_v3"
  document_type = "Command"

  content = <<-EOF
  {
    "schemaVersion": "1.2",
    "description": "Install Docker on CentOS Stream 9",
    "runtimeConfig": {
      "aws:runShellScript": {
        "properties": [
          {
            "id": "runShellScript_v3",
            "runCommand": [
              "sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo",
              "sudo dnf install docker-ce docker-ce-cli containerd.io --nobest -y",
              "sudo systemctl start docker",
              "sudo systemctl enable docker",
              "sudo usermod -aG docker ssm-user",
              "sudo usermod -aG docker centos",
              "newgrp docker",
              "sudo systemctl restart docker"
            ]
          }
        ]
      }
    }
  }
  EOF
}


resource "aws_ssm_association" "install_docker_primary" {
  name        = aws_ssm_document.install_docker.name
  instance_id = var.control_plane_primary_instance_id
}
resource "aws_ssm_association" "install_docker_secondary" {
  name        = aws_ssm_document.install_docker.name
  instance_id = var.control_plane_secondary_instance_id
}
