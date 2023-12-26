resource "aws_iam_policy" "iam_policy" {
  name  = "${var.tag_path}.iam_policy-${var.policy_name}"

  policy  = "${var.policy_json}"
}