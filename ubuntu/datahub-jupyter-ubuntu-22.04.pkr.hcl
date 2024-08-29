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

source "qemu" "datahub_jupyter_ubuntu_22_04" {
  boot_command              = [
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall ds=\"nocloud-net;seedfrom=http://{{ .HTTPIP }}:{{ .HTTPPort }}/\"",
    " PACKER_USER=ubuntu PACKER_AUTHORIZED_KEY={{ `${var.SSH_PUB_KEY}` | urlquery }}",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot",
    "<enter>"
  ]
  boot_wait                 = "5s"
  disk_size                 = 8000
  format                    = "qcow2"
  headless                  = true
  http_directory            = "httpdir"
  http_port_max             = 8550
  http_port_min             = 8500
  iso_checksum              = "sha256:45f873de9f8cb637345d6e66a583762730bbea30277ef7b32c9c3bd6700a32b2"
  iso_url                   = "https://releases.ubuntu.com/jammy/ubuntu-22.04.4-live-server-amd64.iso"
  memory                    = 1024
  qemuargs                  = [["-cpu", "host"]]
  shutdown_command          = "sudo -- sh -c 'rm /etc/sudoers.d/99-egi-installation && shutdown -h now'"
  ssh_clear_authorized_keys = true
  ssh_private_key_file      = "${var.SSH_PRIVATE_KEY_FILE}"
  ssh_timeout               = "20m"
  ssh_username              = "ubuntu"
  vm_name                   = "DataHub-Jupyter-Ubuntu.22.04-2024.03.21"
}

build {
  sources = ["source.qemu.datahub_jupyter_ubuntu_22_04"]

  provisioner "ansible" {
    playbook_file = "provisioners/init.yaml"
    use_proxy     = false
    user          = "ubuntu"
  }

  provisioner "ansible" {
    pause_before  = "30s"
    playbook_file = "provisioners/datahub-jupyter.yaml"
    use_proxy     = false
    user          = "ubuntu"
  }

  provisioner "shell" {
    script = "provisioners/cleanup.sh"
  }

}
