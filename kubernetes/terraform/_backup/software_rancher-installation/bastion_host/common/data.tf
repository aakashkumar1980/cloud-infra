data "aws_instances" "selected-aws_instance" {
  filter {
    name   = "tag:Name"
    values = ["${var.tagname}"]
  }
  instance_state_names = ["running"]
}
