# ################ #
# EFS INSTALLATION #
# ################ #
# Ensure the latest updates are installed
sudo dnf update -y

# Install NFS utilities and EFS utilities
sudo dnf install git nfs-utils rpm-build make -y

sudo git clone https://github.com/aws/efs-utils
cd efs-utils
sudo make rpm
sudo yum install build/amazon-efs-utils*rpm -y

# Give system user access to EFS
sudo chown ssm-user:ssm-user /mnt/efs
sudo chmod 775 /mnt/efs

# Create a directory for your EFS mount
mkdir /mnt/efs
# Mount the EFS file system using the DNS name
mount -t efs -o tls ${efs_id}.efs.${aws_region}.amazonaws.com:/ /mnt/efs

# Optional: Add an entry to /etc/fstab to mount EFS on reboot
echo '${efs_id}.efs.${aws_region}.amazonaws.com:/ /mnt/efs efs tls,_netdev 0 0' >> /etc/fstab
# Reboot the instance to test fstab entry effectiveness
sleep 30
sudo reboot
