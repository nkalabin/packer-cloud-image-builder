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

source "qemu" "debian-11" {
  iso_urls       = [
    "debian-11.11.0-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/archive/11.11.0/amd64/iso-cd/debian-11.11.0-amd64-netinst.iso"
  ]
  iso_checksum   = "sha256:cd5b2a6fc22050affa1d141adb3857af07e94ff886dca1ce17214e2761a3b316"
  vm_name        = "debian-11-packer.qcow2"
  format         = "qcow2"
  output_directory = "output-debian-11-qemu"
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
  name = "debian-11-qemu-build"
  
  sources = [
    "source.qemu.debian-11"
  ]

  provisioner "shell" {
    execute_command = "echo '${var.user_pass}' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
    script          = "scripts/cleanup.sh"
    expect_disconnect = true
  }
}