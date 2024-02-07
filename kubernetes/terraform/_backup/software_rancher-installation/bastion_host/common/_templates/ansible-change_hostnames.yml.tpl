- name: # Changing Hostnames for Kubernetes cluster servers
  gather_facts: false
  hosts: kubernetes_cluster
  tasks:
  - name: # 1. updating the latest packages...
    shell: | 
      yum update -y
    become: true  

  - name: # 2. installing tools...
    shell: | 
      yum install yum-versionlock -y
      yum install wget -y
    become: true  

  - name: # 3. swapping off...
    shell: | 
      swapoff -a    
    become: true

  - name: # 4. changing hostnames...
    shell: | 
      echo "{{inventory_hostname_short}}" > /etc/hostname
      echo "127.0.0.1   {{inventory_hostname_short}}" >> /etc/hosts
      echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg
    become: true  
    register: mylogs_4
  - debug: msg="{{mylogs_4.stdout_lines}}"
  - debug: msg="{{mylogs_4.stderr_lines}}" 	        


  - name: # 5. reboot servers...
    shell: |  
      sleep 2m
      shutdown -r +1
    become: true
