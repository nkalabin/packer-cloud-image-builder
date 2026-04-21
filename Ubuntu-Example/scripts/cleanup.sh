#!/bin/bash
set -euo pipefail

rm -f /etc/cloud/cloud.cfg.d/99-installer.cfg
rm -f /etc/cloud/cloud-init.disabled

cat > /etc/cloud/cloud.cfg.d/99_enable_all_datasources.cfg <<'EOF'
datasource_list: [ NoCloud, ConfigDrive, OVF, MAAS, VMware, OpenStack, CloudStack, Ec2, Azure, GCE, Oracle, Aliyun ]
EOF

if [ -f /etc/default/grub ]; then
  sed -i 's#^GRUB_CMDLINE_LINUX_DEFAULT=.*#GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 console=ttyS0,115200 earlyprintk=ttyS0,115200 loglevel=7"#' /etc/default/grub || true
  sed -i 's#^GRUB_CMDLINE_LINUX=.*#GRUB_CMDLINE_LINUX=""#' /etc/default/grub || true
  command -v update-grub >/dev/null 2>&1 && update-grub || true
fi

if command -v cloud-init >/dev/null 2>&1; then
  cloud-init clean --logs --reboot || true
fi

export DEBIAN_FRONTEND=noninteractive
apt update -y
apt upgrade -y
apt install -y --no-install-recommends openssh-server
apt autoremove -y
apt clean

if [ -f /etc/machine-id ]; then
  truncate -s 0 /etc/machine-id || true
fi
rm -f /var/lib/dbus/machine-id
ln -sf /etc/machine-id /var/lib/dbus/machine-id

set +e
dd if=/dev/zero of=/EMPTY bs=1M count=1024 >/dev/null 2>&1 || true
rm -f /EMPTY
set -e

sync
