#!/bin/bash

echo "[START] destroying usecase:kubernetes..."
cd "/home/ubuntu/Desktop/PRIVATE-LEARNINGv2/PROJECTS/learning/Cloud/kubernetes/certified_kubernetes_administrator(cka)/servers/iaas"
if [ -e output4debug.json ]
then
    terraform destroy -auto-approve=true
    rm output4debug.json

    cd "/home/ubuntu/Desktop/PRIVATE-LEARNINGv2/PROJECTS/learning/Cloud"
    echo "destroying usecase:vpc_peering as Kubernetes & other configurations needs to be destroyed "
    sh _stop-vpc_peering.sh    
else
    echo "'usecase:kubernetes' already destroyed..."
fi
echo "[END] destroying usecase:kubernetes..."