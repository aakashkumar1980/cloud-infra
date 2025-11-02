[control_plane]
control_plane_primary ansible_host=${control_plane_primary_instance_private_ip}

[nodes]
node1 ansible_host=${node1_instance_private_ip}
node2 ansible_host=${node2_instance_private_ip}


[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=/mnt/ebs_volume/PrivateLearningV2.1/apps-configs/security/ssh/keys/id_rsa_ec2-decrypted.pem