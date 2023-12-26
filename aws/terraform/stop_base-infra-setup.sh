#!/bin/bash

# ####################### #
# BASE-SETUP INSTALLATION #
# ####################### #
echo "[START] installing 'base-infra-setup'..."
cd `pwd`/base-infra-setup

terraform destroy -auto-approve=true -compact-warnings

cd `pwd`
echo "[END] installing 'base-infra-setup'..."