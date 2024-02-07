resource "aws_ec2_tag" "ec2_tag-update" {
  resource_id = data.aws_instance.selected-aws_instance.instance_id
  key         = "UseCase"
  value       = "${var.tag_path}.${var.hostname}"
}
