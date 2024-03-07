#!/bin/bash

BASE_PATH=$LEARNING_HOME/cloud-infra/aws/terraform
KUBERNETES_PATH=$LEARNING_HOME/cloud-infra/kubernetes
# ####################### #
# KUBERNETES UNSTALLATION #
# ####################### #
echo "[START] un-installing 'kubernetes-infra-setup'..."
cd $KUBERNETES_PATH/terraform
# DESTROY KUBERNETES INFRASTRUCTURE
echo "Destroying kubernetes-infra-setup..."
terraform destroy -auto-approve=true

echo "stopping 'ec2_natgateway_server'."
$BASE_PATH/_stop-ec2_natgateway_server.sh
echo "[END] un-installing 'kubernetes-infra-setup'..."