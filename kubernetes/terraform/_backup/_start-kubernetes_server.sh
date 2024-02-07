#!/bin/bash

# ################ #
# PRE-FLIGHT CHECK #
# ################ #
# CHECKING IF "USECASE-VPC-PEERING" MODULE IS INSTALLED
cd "/home/ubuntu/Desktop/PRIVATE-LEARNINGv2/PROJECTS/learning/Cloud/aws/aws_certified_solutions_architect/usecases/networking/site-to-site connection/vpc-peering"
if [ -e output4debug.json ]
then
    echo "'usecase:vpc-peering' already installed..."

# INSTALL "USECASE-VPC-PEERING" FIRST
else
    cd "/home/ubuntu/Desktop/PRIVATE-LEARNINGv2/PROJECTS/learning/Cloud"
    bash _start-vpc_peering.sh
    sleep 2m
fi


# ################################ #
# USECASE: KUBERNETES INSTALLATION #
# ################################ #
echo "[START] installing 'kubernetes'..."
cd "/home/ubuntu/Desktop/PRIVATE-LEARNINGv2/PROJECTS/learning/Cloud/kubernetes/certified_kubernetes_administrator(cka)/servers/iaas"
terraform init
terraform apply -auto-approve=true -compact-warnings
echo "" > output4debug.json
echo "[END] installing 'kubernetes'..."


# MISCELLENOUS COMMANDS #
echo "STOPPING extra resources to save cost."
aws ec2 stop-instances \
--region us-east-1 \
--profile privatelearningv2 \
--no-cli-pager \
--instance-ids $(aws ec2 describe-instances \
    --filters \
        Name=tag:Name,Values=_terraform.usecase-site2site-vpc_peering.vpc-center.ec2_public-server \
        Name=instance-state-name,Values=running \
    --output text \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --region us-east-1 \
    --profile privatelearningv2)

# formatting .kube/config file
bash /home/ubuntu/Desktop/PRIVATE-LEARNINGv2/PROJECTS/learning/Cloud/kubernetes/certified_kubernetes_administrator\(cka\)/_learning/.kube/format-config.sh
# start kubernetesUI tool
octant --kubeconfig /home/ubuntu/Desktop/PRIVATE-LEARNINGv2/PROJECTS/learning/Cloud/kubernetes/certified_kubernetes_administrator\(cka\)/_learning/.kube/config  
