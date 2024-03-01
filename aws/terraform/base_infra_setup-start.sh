#!/bin/bash

BASE_PATH=/home/ubuntu/Desktop/cloud-infra/aws/terraform
# ####################### #
# BASE-SETUP INSTALLATION #
# ####################### #
echo "[START] installing 'base-infra-setup'..."
cd $BASE_PATH/base-infra-setup
terraform init -upgrade
terraform apply -auto-approve=true

$BASE_PATH/_ec2_natgateway_server-stop.sh
echo "[END] installing 'base-infra-setup'..."