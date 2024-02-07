locals {
  # HIBERNATE (Enable only if there is major change in the network)
  #vpc-peering = {
  #  output4debug-file = jsondecode(file("${path.cwd}/../../../../aws/aws_certified_solutions_architect/usecases/networking/site-to-site connection/vpc-peering/output4debug.json"))
  #}
    
  server = {
    installation_type = "iaas"

    # need for copying to kubernetes config to the privatelearningv2 dev. server
    privatelearningv2 = {
      tagname = "PrivateLearningV2"
    }
    # need for connecting to kubernetes cluster for software setup
    bastion_host = {
      tagname = "_terraform.usecase-site2site-vpc_peering.vpc-center.ec2_public-server"
    }

    aws_keypair = "_terraform.keypair"
    control_planes = {
      server1 = {
        tagname  = "_terraform.usecase-site2site-vpc_peering.vpc-center.ec2_private-server"
        hostname = "cplane1b"
        ports = {
          # public access
          api_server = "6443"
          # private
          etcd               = "2379-2380"
          scheduler          = "10251"
          controller_manager = "10252"
          kubelet            = "10250"
        }
      }
    }

    nodes = {
      "region_nvirginia" = {
        servers = [
          {
            tagname  = "_terraform.usecase-site2site-vpc_peering.vpc-left.ec2_private-server"
            hostname = "node1a"
          }
        ]
      }
      "region_london" = {
        servers = [
          {
            tagname  = "_terraform.usecase-site2site-vpc_peering.vpc-right.ec2_private-server"
            hostname = "node2c"
          }
        ]
      }
      ports = {
        # control_plane access
        kubelet = "10250"
        # private
        nodeport = {
          from_port = "30000"
          to_port = "32767"
        }
      }

    }
  }
}
