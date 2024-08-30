packer {
  required_plugins {
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

variable "SSH_PRIVATE_KEY_FILE" {
  type    = string
  default = ""
}

variable "SSH_PUB_KEY" {
  type    = string
  default = ""
}

source "qemu" "alma_9" {
  boot_command              = [
    "<esc>",
    "linux inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/alma-9.cfg.tpl",
    " PACKER_USER=root PACKER_AUTHORIZED_KEY={{ `${var.SSH_PUB_KEY}` | urlquery }}",
    "<enter>"
  ]
  boot_wait                 = "3s"
  disk_size                 = 8000
  format                    = "qcow2"
  headless                  = true
  http_directory            = "httpdir"
  http_port_max             = 8550
  http_port_min             = 8500
  iso_checksum              = "sha256:1e5d7da3d84d5d9a5a1177858a5df21b868390bfccf7f0f419b1e59acc293160"
  iso_url                   = "https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9-latest-x86_64-boot.iso"
  memory                    = 1024
  qemuargs                  = [["-cpu", "host"]]
  shutdown_command          = "shutdown -h now"
  ssh_private_key_file      = "${var.SSH_PRIVATE_KEY_FILE}"
  ssh_timeout               = "90m"
  ssh_username              = "root"
  ssh_password              = "rootpassword"
  vm_name                   = "alma.9-2024.08.29"
}

build {
  sources = ["source.qemu.alma_9"]

  provisioner "ansible" {
    playbook_file = "provisioners/config.yml"
    use_proxy     = false
  }

  provisioner "shell" {
    script = "provisioners/cleanup.sh"
  }

}
