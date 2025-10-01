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
  default = "ubuntu"
  description = "Имя пользователя для SSH-подключения во время сборки."
}

variable "user_pass" {
  type    = string
  default = "ubuntu"
  description = "Пароль пользователя для SSH-подключения во время сборки."
  sensitive = true
}

source "qemu" "ubuntu-2404" {
  # Основные параметры образа
  iso_urls       = [
    "ubuntu-24.04.3-live-server-amd64.iso",
    "https://releases.ubuntu.com/noble/ubuntu-24.04.3-live-server-amd64.iso"
  ]
  iso_checksum   = "sha256:c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b"
  vm_name        = "ubuntu-24.04-packer.qcow2"
  format         = "qcow2"
  output_directory = "output-ubuntu-2404-qemu" # Добавлено для явного указания
  qemu_binary = "/opt/homebrew/bin/qemu-system-x86_64"
  # Параметры виртуальной машины
  disk_size      = "10000M"
  memory         = 4096
  cpus           = 4
  headless       = var.is_headless
  display        = "cocoa"
  accelerator    = "tcg"
  net_device     = "virtio-net"
  disk_interface = "virtio"

  # Параметры установки и загрузки
  boot_wait          = "5s"
  boot_key_interval  = "50ms"
  http_directory     = "http"
  boot_command       = [
    "e<wait>",
    "<down><down><down>",
    "<end><bs><bs><bs><bs><wait>",
    "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
    "<f10><wait>"
  ]
  # Отключение ACPI и флоппи-диска
  qemuargs = []
  
  # Параметры SSH
  ssh_username           = var.user_name
  ssh_password           = var.user_pass
  ssh_timeout            = "60m"
  ssh_handshake_attempts = 420
}

build {
  name = "ubuntu-server-qemu-build"
  
  sources = [
    "source.qemu.ubuntu-2404"
  ]

  provisioner "shell" {
    execute_command = "echo '${var.user_pass}' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
    script          = "scripts/cleanup.sh"
    expect_disconnect = true
  }
}