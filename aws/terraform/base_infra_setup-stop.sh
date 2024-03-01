#!/bin/bash

BASE_PATH=/home/ubuntu/Desktop/cloud-infra/aws/terraform
KUBERNETES_PATH=/home/ubuntu/Desktop/cloud-infra/kubernetes
# ######################## #
# OTHER SETUP UNSTALLATION #
# ######################## #
echo "stopping 'kubernetes-infra-setup' if not stopped..."
$KUBERNETES_PATH/kubernetes_infra_setup-stop.sh


# ####################### #
# BASE-SETUP UNSTALLATION #
# ####################### #
echo "[STOP] un-installing 'base-infra-setup'..."
cd $BASE_PATH/base-infra-setup
terraform destroy -auto-approve=true

echo "[END] un-installing 'base-infra-setup'..."