#!/bin/bash

BASE_PATH=/home/ubuntu/Desktop/cloud-infra/aws/terraform
KUBERNETES_PATH=/home/ubuntu/Desktop/cloud-infra/kubernetes
TIMER_PATH=/home/ubuntu/Desktop/apps-templates/utils
# ####################### #
# BASE-SETUP INSTALLATION #
# ####################### #
echo "starting 'base-infra-setup' if not started..."
$BASE_PATH/base_infra_setup-start.sh
echo "starting 'ec2_natgateway_server'."
$BASE_PATH/_ec2_natgateway_server-start.sh


# ####################### #
# KUBERNETES INSTALLATION #
# ####################### #
echo "[START] Installing kubernetes-infra-setup in 4 minute/s (waiting for ec2_natgateway_servers to get up)..."
$TIMER_PATH/timer.sh 4

cd $KUBERNETES_PATH/terraform
terraform init -upgrade
terraform apply -auto-approve=true

echo "[END] installing 'kubernetes-infra-setup'..."