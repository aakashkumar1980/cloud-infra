#!/bin/bash

# ####################### #
# BASE-SETUP INSTALLATION #
# ####################### #
echo "[START] un-installing 'kubernetes-infra-setup'..."
cd `pwd`/servers
# DESTROY KUBERNETES INFRASTRUCTURE
echo "Destroying kubernetes-infra-setup..."
terraform destroy -auto-approve=true

../../../aws/terraform/_ec2_natgateway_server-stop.sh
echo "[END] un-installing 'kubernetes-infra-setup'..."