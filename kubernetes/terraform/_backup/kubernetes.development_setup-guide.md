<style>
r { color: Red }
o { color: Orange }
g { color: Green }
</style>

# KUBECTL
```sh
$ sudo apt update

$ curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
$ sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
$ kubectl version --client --output=yaml

$ rm -r kubectl

```
</br>

# KubernetesUI Tools
Download the below tools
- Lens (*paid)
- octant
  ```sh
  $ cd ~/Desktop/Softwares   
  $ wget https://github.com/vmware-tanzu/octant/releases/download/v0.25.1/octant_0.25.1_Linux-64bit.deb
  $ sudo dpkg -i octant_0.25.1_Linux-64bit.deb
  
  ```
  (check the version)
  > To Run: $ octant