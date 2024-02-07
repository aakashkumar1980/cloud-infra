#!/bin/bash

# ####################### #
# BASE-SETUP INSTALLATION #
# ####################### #
echo "[START] installing 'kubernetes-infra-setup'..."
../aws/terraform/_ec2_natgateway_server-start.sh


# FINALLY INSTALL KUBERNETES INFRASTRUCTURE
echo "Installing kubernetes-infra-setup in 4 minute/s (waiting for ec2_natgateway_servers to get up)..."
#../../apps-templates/utils/timer.sh 4

cd `pwd`/terraform
terraform init -upgrade
terraform apply -auto-approve=true

echo "[END] installing 'kubernetes-infra-setup'..."