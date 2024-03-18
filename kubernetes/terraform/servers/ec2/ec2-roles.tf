resource "aws_iam_role_policy_attachment" "ssm-policy_attachment" {
  role       = aws_iam_role.role-ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_read_only-policy_attachment" {
  role       = aws_iam_role.role-ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

/**
resource "aws_iam_policy" "custom_efs_access" {
  name        = "${var.ns}.customEFS-fullaccess"
  path        = "/"
  description = "Custom policy that grants full access to EFS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "elasticfilesystem:*",
        Resource = "*",
      },
    ],
  })
}
resource "aws_iam_role_policy_attachment" "efs_full_access-policy_attachment" {
  role       = aws_iam_role.role-ec2.name
  policy_arn = aws_iam_policy.custom_efs_access.arn
}
**/

resource "aws_iam_role" "role-ec2" {
  name = "${var.ns}.role-ec2"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_instance_profile" "instance_profile-ec2" {
  name = "${var.ns}.instance_profilex-ec2"
  role = aws_iam_role.role-ec2.name
}



