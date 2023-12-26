resource "aws_instance" "ec2" {
  ami           = var.ami
  instance_type = (var.instance_type != null) ? var.instance_type : "t3a.nano"
  key_name      = var.keypair

  root_block_device {
    volume_size = 10
    volume_type = "standard"
    tags = tomap({
      "Name" = "${var.tag_path}.volume_${var.entity_name}"
    })
  }
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.eni.id
  }

  user_data = var.user_data
  metadata_options {
    instance_metadata_tags = "enabled"
    http_endpoint = "enabled"
  }
  tags = tomap({
    "Name" = "${var.tag_path}.ec2_${var.entity_name}"
  })
}
