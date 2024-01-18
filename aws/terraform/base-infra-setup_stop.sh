#!/bin/bash

# ####################### #
# BASE-SETUP INSTALLATION #
# ####################### #
echo "[START] un-installing 'base-infra-setup'..."
cd `pwd`/base-infra-setup

terraform destroy -auto-approve=true

cd `pwd`
echo "[END] un-installing 'base-infra-setup'..."