#!/bin/bash

source ./cluster.properties
ssh -i "/mnt/ebs_volume/PrivateLearningV2.1/apps-configs/security/ssh/keys/id_rsa_ec2-decrypted.pem" ec2-user@"$KUBERNETES_CONTROL_PLANE_IP"