locals {
  user_data_efs = templatefile("${path.module}/efs_mount.tpl", { efs_id = "${var.efs_file_system.id}", aws_region = "${data.aws_region.current.name}" })
}
