#!/bin/bash

echo "Stopping ec2_natgateway-server with specified tags to save costs."
# First stop-instances command
aws ec2 stop-instances \
--region us-east-1 \
--profile default \
--instance-ids \
    $(aws ec2 describe-instances \
    --filters \
        "Name=tag:Name,Values=\
        _terraform.vpc_b.subnet_generic-az_a.ec2_natgateway-server" \
        "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[*].Instances[*].InstanceId' \
    --region us-east-1 \
    --profile default \
    --no-cli-pager) > /dev/null 2>&1

# Second stop-instances command
aws ec2 stop-instances \
--region eu-west-2 \
--profile secondary \
--instance-ids \
    $(aws ec2 describe-instances \
    --filters \
        "Name=tag:Name,Values=\
        _terraform.vpc_c.subnet_generic-az_a.ec2_natgateway-server,\
        _terraform.vpc_acopy.subnet_generic-az_a.ec2_natgateway-server" \
        "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[*].Instances[*].InstanceId' \
    --region eu-west-2 \
    --profile secondary \
    --no-cli-pager) > /dev/null 2>&1
