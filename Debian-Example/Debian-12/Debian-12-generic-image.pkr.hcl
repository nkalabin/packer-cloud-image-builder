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

source "qemu" "debian-12" {
  iso_urls       = [
    "debian-12.12.0-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/archive/12.12.0/amd64/iso-cd/debian-12.12.0-amd64-netinst.iso"
  ]
  iso_checksum   = "sha256:dfc30e04fd095ac2c07e998f145e94bb8f7d3a8eca3a631d2eb012398deae531"
  vm_name        = "debian-12-packer.qcow2"
  format         = "qcow2"
  output_directory = "output-debian-12-qemu"
  qemu_binary = "/usr/bin/qemu-system-x86_64" #"/opt/homebrew/bin/qemu-system-x86_64"
  disk_size      = "10000M"
  memory         = 4096
  cpus           = 4
  headless       = var.is_headless
  display        = "gtk" #"cocoa"
  accelerator    = "kvm" #"tcg"
  net_device     = "virtio-net"
  disk_interface = "virtio"
  boot_wait          = "5s"
  boot_key_interval  = "50ms"
  http_directory     = "http"
  boot_command       = [
    "<esc><wait>",
    "install auto=true priority=critical preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg debian-installer/locale=en_US keyboard-configuration/xkb-keymap=us netcfg/choose_interface=auto<enter>"
  ]
  qemuargs = [
    ["-cpu", "max"],
    ["-serial", "stdio"],
    ["-device", "virtio-serial"],
    ["-chardev", "socket,path=/tmp/console.sock,server=on,wait=off,id=console"],
    ["-device", "virtconsole,chardev=console"],
  ]
  ssh_username           = var.user_name
  ssh_password           = var.user_pass
  ssh_timeout            = "60m"
  ssh_handshake_attempts = 420
}

build {
  name = "debian-12-qemu-build"
  
  sources = [
    "source.qemu.debian-12"
  ]

  provisioner "shell" {
    execute_command = "echo '${var.user_pass}' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
    script          = "scripts/cleanup.sh"
    expect_disconnect = true
  }
}