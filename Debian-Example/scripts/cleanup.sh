#!/bin/bash
set -euo pipefail

rm -f /etc/cloud/cloud.cfg.d/99-installer.cfg || true
rm -f /etc/cloud/cloud-init.disabled || true

mkdir -p /etc/cloud/cloud.cfg.d
cat > /etc/cloud/cloud.cfg.d/99_enable_all_datasources.cfg <<'EOF'
datasource_list: [ NoCloud, ConfigDrive, OVF, MAAS, VMware, OpenStack, CloudStack, Ec2, Azure, GCE, Oracle, Aliyun ]
EOF

if [ -f /etc/default/grub ]; then
  sed -i 's#^GRUB_CMDLINE_LINUX_DEFAULT=.*#GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 console=ttyS0,115200 earlycon=ttyS0,115200 loglevel=7"#' /etc/default/grub || true
  sed -i 's#^GRUB_CMDLINE_LINUX=.*#GRUB_CMDLINE_LINUX=""#' /etc/default/grub || true
  command -v update-grub >/dev/null 2>&1 && update-grub || true
fi

if command -v cloud-init >/dev/null 2>&1; then
  cloud-init clean --logs --reboot || true
fi

export DEBIAN_FRONTEND=noninteractive
apt update -y
apt upgrade -y
apt install -y --no-install-recommends openssh-server cloud-guest-utils cloud-initramfs-growroot
apt autoremove -y
apt clean

if [ -f /etc/machine-id ]; then
  truncate -s 0 /etc/machine-id || true
fi
rm -f /var/lib/dbus/machine-id
ln -sf /etc/machine-id /var/lib/dbus/machine-id

# Remove SSH host keys to force regeneration on first boot
rm -f /etc/ssh/ssh_host_* || true

set +e
dd if=/dev/zero of=/EMPTY bs=1M count=1024 >/dev/null 2>&1 || true
rm -f /EMPTY
set -e

sync
