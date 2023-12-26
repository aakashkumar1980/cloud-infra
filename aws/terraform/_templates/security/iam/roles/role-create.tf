resource "aws_iam_role" "iam_role" {
  name = "${var.tag_path}.iam-role_${var.role_name}"
  assume_role_policy = "${var.policy_json}"

  tags = tomap({
    "Name" = "${var.tag_path}.iam_role-${var.role_name}"
  })  
}