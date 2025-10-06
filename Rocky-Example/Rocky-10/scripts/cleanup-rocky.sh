#!/bin/bash
set -euo pipefail

echo "Updating the system..."
dnf -y update

echo "Installing cloud-init and cloud-utils..."
dnf -y install cloud-init cloud-utils-growpart python3

cat > /etc/cloud/cloud.cfg.d/99_openstack.cfg <<'EOF'
datasource_list: [ OpenStack, NoCloud, ConfigDrive ]
disable_root: false
ssh_pwauth: true
ssh_authorized_keys: []
system_info:
  default_user:
    name: rocky
    lock_passwd: false
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/bash
EOF

if [ -f /etc/default/grub ]; then
  sed -i 's/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0"/' /etc/default/grub
  
  if command -v grub2-mkconfig >/dev/null 2>&1; then
    grub2-mkconfig -o /boot/grub2/grub.cfg
  fi
fi

systemctl enable serial-getty@ttyS0.service
systemctl enable cloud-init.service
systemctl enable cloud-init-local.service
systemctl enable cloud-config.service
systemctl enable cloud-final.service

mkdir -p /etc/systemd/system/serial-getty@ttyS0.service.d/
cat > /etc/systemd/system/serial-getty@ttyS0.service.d/override.conf <<'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -- \\u' --keep-baud 115200,38400,9600 --noclear %I $TERM
EOF

echo "Cleaning up..."
rm -f /etc/ssh/ssh_host_*
dnf -y remove $(dnf repoquery --installonly --latest-limit=-1 -q)
dnf -y clean all --enablerepo=\*

echo "Cleaning temporary files..."
rm -rf /tmp/* /var/tmp/*
rm -f /var/lib/systemd/random-seed
truncate -s 0 /etc/machine-id

echo "Cleaning history..."
rm -f /root/.wget-hsts
rm -f /root/.bash_history
export HISTSIZE=0

echo "Zeroing empty space..."
dd if=/dev/zero of=/EMPTY bs=1M status=progress || true
rm -f /EMPTY

sync
echo "Cleanup completed successfully"