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
  default = "rocky"
}

variable "user_pass" {
  type      = string
  default   = "rocky"
  sensitive = true
}

source "qemu" "rocky-9" {
  iso_urls = [
    "Rocky-9.6-x86_64-minimal.iso",
    "https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9.6-x86_64-minimal.iso"
  ]
  iso_checksum   = "file:https://download.rockylinux.org/pub/rocky/9/isos/x86_64/CHECKSUM"
  vm_name        = "rocky-9.6.qcow2"
  format         = "qcow2"
  output_directory = "output-rocky-9-qemu"
  qemu_binary    = "/opt/homebrew/bin/qemu-system-x86_64"
  disk_size      = "10000M"
  memory         = 4096
  cpus           = 8
  headless       = var.is_headless
  display        = "cocoa"
  accelerator    = "tcg"
  net_device     = "virtio-net"
  disk_interface = "virtio"
  boot_wait      = "10s"
  boot_key_interval = "50ms"
  http_directory = "http"
  boot_command = [
    "<tab>inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter><wait>"
  ]
  qemuargs = [
    ["-cpu", "max"],
    ["-serial", "stdio"],
    ["-device", "virtio-serial"],
    ["-chardev", "socket,path=/tmp/console.sock,server=on,wait=off,id=console"],
    ["-device", "virtconsole,chardev=console"],
  ]

  ssh_username         = var.user_name
  ssh_password         = var.user_pass
  ssh_timeout          = "60m"
  ssh_handshake_attempts = 420
}

build {
  name = "rocky-9-qemu-build"

  sources = [
    "source.qemu.rocky-9"
  ]

  provisioner "shell" {
    execute_command = "echo '${var.user_pass}' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
    script          = "scripts/cleanup-rocky.sh"
    expect_disconnect = true
  }
}