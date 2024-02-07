data "aws_instances" "selected-aws_instances" {
  filter {
    name   = "tag:Name"
    values = ["${var.tagname}"]
  }
  instance_state_names = ["running"]
}
data "aws_instance" "selected-aws_instance" {
  instance_id = join("", data.aws_instances.selected-aws_instances.ids)

}

data "aws_network_interface" "selected-aws_network_interface" {
  filter {
    name   = "attachment.instance-id"
    values = [data.aws_instance.selected-aws_instance.instance_id]
  }
}


data "aws_subnet" "selected-aws_subnet" {
  id = data.aws_instance.selected-aws_instance.subnet_id
}

