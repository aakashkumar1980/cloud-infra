#!/bin/bash

# ####################### #
# BASE-SETUP INSTALLATION #
# ####################### #
echo "[START] installing 'base-infra-setup'..."
cd `pwd`/base-infra-setup
terraform init -upgrade
terraform apply -auto-approve=true

../_ec2_natgateway_server-stop.sh
echo "[END] installing 'base-infra-setup'..."