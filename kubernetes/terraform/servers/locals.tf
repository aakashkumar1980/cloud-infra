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
        # public access
        api_server = "6443"

        # private
        etcd               = "2379-2380"
        scheduler          = "10251"
        controller_manager = "10252"
        kubelet            = "10250"
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
        # control_plane access
        kubelet = "10250"

        # private
        nodeport = {
          from_port = "30000"
          to_port   = "32767"
        }
      }
    }


  }

}
