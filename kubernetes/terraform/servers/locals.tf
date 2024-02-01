locals {

  servers = {
    control_planes = {
      cluster = {
        vpc_c = {
          hostname_primary   = "cplane_active"
          hostname_secondary = "cplane_standby"
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
        vpc_ab = [{
          vpc      = "vpc_a",
          hostname = "node1"
          }, {
          vpc      = "vpc_b",
          hostname = "node2"
          }
        ]
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
