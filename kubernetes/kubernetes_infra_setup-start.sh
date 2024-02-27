#!/bin/bash

# ####################### #
# BASE-SETUP INSTALLATION #
# ####################### #
echo "starting 'base-infra-setup' if not started..."
../aws/terraform/base_infra_setup-start.sh
echo "starting 'ec2_natgateway_server'."
../aws/terraform/_ec2_natgateway_server-start.sh


# ####################### #
# KUBERNETES INSTALLATION #
# ####################### #
echo "[START] Installing kubernetes-infra-setup in 4 minute/s (waiting for ec2_natgateway_servers to get up)..."
../../apps-templates/utils/timer.sh 4

cd `pwd`/terraform
terraform init -upgrade
terraform apply -auto-approve=true

echo "[END] installing 'kubernetes-infra-setup'..."