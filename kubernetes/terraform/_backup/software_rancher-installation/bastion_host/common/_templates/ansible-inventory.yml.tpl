---
all:
  children:
    kubernetes_cluster:
      children:
        control_planes:
          hosts:
            ${server1.hostname}: 
              ansible_host: ${server1.private_ip}
          vars:
            ansible_user: centos
            ansible_private_key_file: /${keypair}

        nodes:
          hosts:
%{ for n in nodes ~}
            ${n.hostname}:
              ansible_host: ${n.private_ip}
%{ endfor ~}
          vars:
            ansible_user: centos
            ansible_private_key_file: /${keypair}