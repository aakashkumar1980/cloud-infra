#!/bin/bash

# ################ #
# SSM INSTALLATION #
# ################ #
# Install the Amazon SSM Agent
sudo dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm

# Enable and start the SSM Agent service
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent