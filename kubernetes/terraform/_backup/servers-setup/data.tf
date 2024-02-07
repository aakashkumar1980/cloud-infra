data "aws_instances" "selected-privatelearningv2-aws_instance" {
  provider = aws.region_mumbai
  
  filter {
    name   = "tag:Name"
    values = ["${local.server.privatelearningv2.tagname}"]
  }
  instance_state_names = ["running"]
}
