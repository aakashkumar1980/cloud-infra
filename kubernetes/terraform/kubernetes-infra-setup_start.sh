#!/bin/bash

# ####################### #
# BASE-SETUP INSTALLATION #
# ####################### #
echo "[START] installing 'kubernetes-infra-setup'..."
../../aws/terraform/_ec2_natgateway_server-start.sh

# FINALLY INSTALL KUBERNETES INFRASTRUCTURE
echo "Installing kubernetes-infra-setup in 4 minutes..."
sleep 4m
cd `pwd`/servers
terraform init -upgrade
terraform apply -auto-approve=true
cd `pwd`
echo "[END] installing 'kubernetes-infra-setup'..."