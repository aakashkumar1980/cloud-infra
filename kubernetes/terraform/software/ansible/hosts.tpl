[control_plane]
control_plane_primary ansible_connection=local ansible_host=${control_plane_primary_instance_private_ip}

[nodes]
node1 ansible_connection=local ansible_host=${node1_instance_private_ip}
node2 ansible_connection=local ansible_host=${node2_instance_private_ip}
