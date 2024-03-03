#!/bin/bash

BASE_PATH=$LEARNING_HOME/cloud-infra/aws/terraform
KUBERNETES_PATH=$LEARNING_HOME/cloud-infra/kubernetes
# ######################## #
# OTHER SETUP UNINSTALLATION #
# ######################## #
echo "stopping 'kubernetes-infra-setup' if not stopped..."
$KUBERNETES_PATH/kubernetes_infra_setup-stop.sh


# ####################### #
# BASE-SETUP UNINSTALLATION #
# ####################### #
echo "[STOP] un-installing 'base-infra-setup'..."
cd $BASE_PATH/base-infra-setup
terraform destroy -auto-approve=true

echo "[END] un-installing 'base-infra-setup'..."