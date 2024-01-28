locals {

  servers = {
    control_planes = {
      cluster = {
        primary = {
          vpc      = "vpc_c",
          hostname = "cplane_active"
        }
        secondary = {
          vpc      = "vpc_b",
          hostname = "cplane_standby"
        }
      }
      ports = {
        ### CONTROL_PLANES ACCESS ###
        # etcd server client API
        etcd = "2379-2380"
        # kube-controller-manager
        controller_manager = "10252"
        # kube-scheduler
        scheduler = "10251"

        ### CONTROL_PLANES + NODES ACCESS ###
        # kubernetes server API
        api_server = "6443"

        ### CONTROL_PLANES + NODES + AUTHORIZED IPS ACCESS ###
        # kubelet API
        kubelet = "10250"
      }
    }

    nodes = {
      cluster = {
        "node1" = {
          vpc      = "vpc_a",
          hostname = "node1a"
        }
        "node2" = {
          vpc      = "vpc_b",
          hostname = "node1b"
        }
        "node3" = {
          vpc      = "vpc_c",
          hostname = "node1c"
        }
      }

      ports = {
        ### CONTROL_PLANES ACCESS ###
        # kubelet API 
        kubelet = "10250"

        ### AUTHORIZED IPS ACCESS ###
        nodeport = {
          from_port = "30000"
          to_port   = "32767"
        }
      }
    }


  }

}
