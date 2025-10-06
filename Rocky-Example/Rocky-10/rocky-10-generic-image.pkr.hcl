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

source "qemu" "rocky-10" {
  iso_urls = [
    "Rocky-10.0-x86_64-minimal.iso",
    "https://download.rockylinux.org/pub/rocky/10/isos/x86_64/Rocky-10.0-x86_64-minimal.iso"
  ]
  iso_checksum   = "sha256:de75c2f7cc566ea964017a1e94883913f066c4ebeb1d356964e398ed76cadd12"
  vm_name        = "rocky-10.qcow2"
  format         = "qcow2"
  output_directory = "output-rocky-10-qemu"
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
    "<up>e<wait><down><down><end> inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<f10>"
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
  name = "rocky-10-qemu-build"

  sources = [
    "source.qemu.rocky-10"
  ]

  provisioner "shell" {
    execute_command = "echo '${var.user_pass}' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
    script          = "scripts/cleanup-rocky.sh"
    expect_disconnect = true
  }
}