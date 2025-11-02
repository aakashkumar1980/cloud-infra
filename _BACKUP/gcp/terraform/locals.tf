locals {
  project = {
    namespace  = "_terraform",
    mime_types = jsondecode(file("${path.module}/../../_sample-data/mime.json"))

    ec2 = {
      nat_instance = {
        instance_type = "t3a.nano"
        region_nvirginia = {
          # amzn-ami-vpc-nat-2018.03.0.20210721.0-x86_64-ebs
          ami = "ami-00a36856283d67c39"
        }
        region_london = {
          # amzn-ami-vpc-nat-2018.03.0.20211001.0-x86_64-ebs
          ami = "ami-00400a198e1509988"
        }
      }

      standard = {
        instance_type = "t3a.nano"
        region_nvirginia = {
          # CentOS Stream 9 x86_64
          ami = "ami-05a66f32ae901754c"
        }
        region_london = {
          # CentOS Stream 9 x86_64
          ami = "ami-0d55375e7a00f3332"
        }
        user_data_ssm = templatefile("${path.module}/ssm_agent.tpl", {})
      }
    }
  }
}
