#!/bin/bash

# ####################### #
# BASE-SETUP INSTALLATION #
# ####################### #
echo "[START] installing 'base-infra-setup'..."
cd `pwd`/base-infra-setup

terraform init
terraform apply -auto-approve=true -compact-warnings

cd `pwd`
echo "[END] installing 'base-infra-setup'..."