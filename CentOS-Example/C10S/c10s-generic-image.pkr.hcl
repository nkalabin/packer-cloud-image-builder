packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

variable "is_headless" {
  type        = bool
  default     = false
  description = "Запуск виртуальной машины QEMU без графического интерфейса."
}

variable "user_name" {
  type        = string
  default     = "centos"
  description = "Имя пользователя для SSH-подключения во время сборки."
}

variable "user_pass" {
  type        = string
  default     = "centos"
  description = "Пароль пользователя для SSH-подключения во время сборки."
  sensitive   = true
}

source "qemu" "centos-10" {
  iso_urls = [
    "CentOS-Stream-10-latest-x86_64-boot.is",
    "https://mirror.stream.centos.org/10-stream/BaseOS/x86_64/iso/CentOS-Stream-10-latest-x86_64-boot.iso"
  ]
  iso_checksum   = "sha256:3dcf347e8ccaa149cf71dca179a3b17ada8b09f32d2b46256918a4626ebee07b"
  vm_name        = "centos-10-stream-packer.qcow2"
  format         = "qcow2"
  output_directory = "output-centos-10-qemu"
  qemu_binary    = "/opt/homebrew/bin/qemu-system-x86_64"
  disk_size      = "10000M"
  memory         = 4096
  cpus           = 8
  headless       = var.is_headless
  display        = "cocoa"
  accelerator    = "tcg"
  net_device     = "virtio-net"
  disk_interface = "virtio"
  boot_wait      = "5s"
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
  name = "centos-10-qemu-build"

  sources = [
    "source.qemu.centos-10"
  ]

  provisioner "shell" {
    execute_command = "echo '${var.user_pass}' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
    script          = "scripts/cleanup-centos.sh"
    expect_disconnect = true
  }
}