#!/bin/bash

# ####################### #
# BASE-SETUP UNSTALLATION #
# ####################### #
echo "stopping 'kubernetes-infra-setup' if not stopped..."
../../kubernetes/kubernetes_infra_setup-stop.sh

echo "[STOP] un-installing 'base-infra-setup'..."
cd `pwd`/base-infra-setup
terraform destroy -auto-approve=true

echo "[END] un-installing 'base-infra-setup'..."