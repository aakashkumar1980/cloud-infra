# Ensure the latest updates are installed
dnf update -y
# Install NFS utilities and EFS utilities
sudo dnf install -y nfs-utils amazon-efs-utils

# Create a directory for your EFS mount
mkdir /mnt/efs
# Mount the EFS file system using the DNS name
mount -t efs -o tls ${efs_id}.efs.${aws_region}.amazonaws.com:/ /mnt/efs

# Optional: Add an entry to /etc/fstab to mount EFS on reboot
echo '${efs_id}.efs.${aws_region}.amazonaws.com:/ /mnt/efs efs tls,_netdev 0 0' >> /etc/fstab
# Reboot the instance to test fstab entry effectiveness
sleep 30
sudo reboot
