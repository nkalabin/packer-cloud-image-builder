packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

variable "is_headless" {
  type    = bool
  default = false
  description = "Запуск виртуальной машины QEMU без графического интерфейса."
}

variable "user_name" {
  type    = string
  default = "debian"
  description = "Имя пользователя для SSH-подключения во время сборки (совпадает с preseed)."
}

variable "user_pass" {
  type    = string
  default = "debian"
  description = "Пароль пользователя для SSH-подключения во время сборки (совпадает с preseed)."
  sensitive = true
}

source "qemu" "debian-13" {
  iso_urls       = [
    "debian-13.1.0-amd64-netinst.iso",
    "https://cdimage.debian.org/debian-cd/13.1.0/amd64/iso-cd/debian-13.1.0-amd64-netinst.iso"
  ]
  iso_checksum   = "file:https://cdimage.debian.org/debian-cd/13.1.0/amd64/iso-cd/SHA512SUMS"
  vm_name        = "debian-13-packer.qcow2"
  format         = "qcow2"
  output_directory = "output-debian-13-qemu"
  qemu_binary = "/opt/homebrew/bin/qemu-system-x86_64"
  disk_size      = "10000M"
  memory         = 4096
  cpus           = 4
  headless       = var.is_headless
  display        = "cocoa"
  accelerator    = "tcg"
  net_device     = "virtio-net"
  disk_interface = "virtio"
  boot_wait          = "5s"
  boot_key_interval  = "50ms"
  http_directory     = "http"
  boot_command       = [
    "<esc><wait>",
    "install auto=true priority=critical preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg debian-installer/locale=en_US keyboard-configuration/xkb-keymap=us netcfg/choose_interface=auto<enter>"
  ]
  qemuargs = []
  ssh_username           = var.user_name
  ssh_password           = var.user_pass
  ssh_timeout            = "60m"
  ssh_handshake_attempts = 420
}

build {
  name = "debian-13-qemu-build"
  
  sources = [
    "source.qemu.debian-13"
  ]

  provisioner "shell" {
    execute_command = "echo '${var.user_pass}' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
    script          = "scripts/cleanup.sh"
    expect_disconnect = true
  }
}