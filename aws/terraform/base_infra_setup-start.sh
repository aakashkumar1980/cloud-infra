#!/bin/bash

BASE_PATH=$LEARNING_HOME/cloud-infra/aws/terraform
TIMER_PATH=$LEARNING_HOME/apps/apps-templates/utils
# ####################### #
# BASE-SETUP INSTALLATION #
# ####################### #
echo "[START] installing 'base-infra-setup'..."
cd $BASE_PATH/base-infra-setup
terraform init -upgrade
terraform apply -auto-approve=true

$BASE_PATH/_ec2_natgateway_server-stop.sh
echo "[END] installing 'base-infra-setup'..."

echo "waiting for base-infra-setup to set up completely..."
$TIMER_PATH/timer.sh 2
