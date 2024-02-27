#!/bin/bash

# ####################### #
# KUBERNETES UNSTALLATION #
# ####################### #
echo "[STOP] un-installing 'kubernetes-infra-setup'..."
cd `pwd`/terraform
# DESTROY KUBERNETES INFRASTRUCTURE
echo "Destroying kubernetes-infra-setup..."
terraform destroy -auto-approve=true

echo "stopping 'ec2_natgateway_server'."
../../aws/terraform/_ec2_natgateway_server-stop.sh
echo "[END] un-installing 'kubernetes-infra-setup'..."