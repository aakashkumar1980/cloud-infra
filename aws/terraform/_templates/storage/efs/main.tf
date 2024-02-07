resource "aws_efs_file_system" "efs_file_system" {
  creation_token = "${var.tag_path}.efs_file_system_${var.entity_name}"

  tags = tomap({
    "Name" = "${var.tag_path}.efs_file_system_${var.entity_name}"
  })
}

resource "aws_efs_mount_target" "efs_mount_target" {
  file_system_id  = aws_efs_file_system.efs_file_system.id
  subnet_id       = var.subnet_id
  security_groups = var.security_groups
}
