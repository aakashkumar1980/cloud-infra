locals {

  servers = {
    control_planes = {
      instance_type = "t3a.micro",
      cluster = {
        primary = {
          vpc      = "vpc_a",
          hostname = "cplane_active"
          type     = "primary"
        }
        secondary = {
          vpc      = "vpc_b",
          hostname = "cplane_standby"
          type     = "secondary"
        }
      }
      ports = {
        ### CONTROL_PLANES ACCESS ###
        # etcd server client API
        etcd = {
          from_port = "2379"
          to_port   = "2380"
          protocol  = "tcp"
        }
        # kube-controller-manager
        controller_manager = {
          from_port = "10252"
          to_port   = "10252"
          protocol  = "tcp"
        }
        # kube-scheduler
        scheduler = {
          from_port = "10251"
          to_port   = "10251"
          protocol  = "tcp"
        }

        ### NODES ACCESS ###
        calico = {
          from_port = "179"
          to_port   = "179"
          protocol  = "tcp"
        }

        ### CONTROL_PLANES + NODES ACCESS ###
        # kubernetes server API
        api_server = {
          from_port = "6443"
          to_port   = "6443"
          protocol  = "tcp"
        }
        dns = {
          from_port = "53"
          to_port   = "53"
          protocol  = "tcp|udp"
        }

        ### CONTROL_PLANES + NODES + AUTHORIZED IPS ACCESS ###
        # kubelet API
        kubelet = {
          from_port = "10250"
          to_port   = "10250"
          protocol  = "tcp"
        }

      }
    }

    nodes = {
      instance_type = "t3a.small",
      cluster = {
        vpc_ab = [{
          vpc      = "vpc_a",
          hostname = "node1"
          }, {
          vpc      = "vpc_b",
          hostname = "node2"
          }, {
          vpc      = "vpc_b",
          hostname = "node3"
          }
        ]
      }

      ports = {
        ### CONTROL_PLANES ACCESS ###
        # kubelet API 
        kubelet = {
          from_port = "10250"
          to_port   = "10250"
          protocol  = "tcp"
        }
        calico = {
          from_port = "179"
          to_port   = "179"
          protocol  = "tcp"
        }

        ### NODES ACCESS ###
        flannel = {
          from_port = "8472"
          to_port   = "8472"
          protocol  = "udp"
        }
        weave = {
          from_port = "6783"
          to_port   = "6784"
          protocol  = "tcp|udp"
        }
        calico = {
          from_port = "179"
          to_port   = "179"
          protocol  = "tcp"
        }

        ### CONTROL_PLANES + NODES ACCESS ###
        dns = {
          from_port = "53"
          to_port   = "53"
          protocol  = "tcp|udp"
        }

        ### AUTHORIZED IPS ACCESS ###
        nodeport = {
          from_port = "30000"
          to_port   = "32767"
          protocol  = "tcp"
        }
      }
    }

  }

}
