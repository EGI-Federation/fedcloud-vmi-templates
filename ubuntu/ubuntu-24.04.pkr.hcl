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

variable "image_tag" {
  type    = string
  default = ""
}

source "qemu" "ubuntu_24_04" {
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
  boot_wait                 = "6s"
  disk_size                 = 8000
  format                    = "qcow2"
  headless                  = true
  http_directory            = "httpdir"
  http_port_max             = 8550
  http_port_min             = 8500
  iso_checksum              = "sha256:d6dab0c3a657988501b4bd76f1297c053df710e06e0c3aece60dead24f270b4d"
  iso_url                   = "https://releases.ubuntu.com/24.04/ubuntu-24.04.2-live-server-amd64.iso"
  memory                    = 1024
  qemuargs                  = [["-cpu", "host"]]
  shutdown_command          = "sudo -- sh -c 'rm /etc/sudoers.d/99-egi-installation && shutdown -h now'"
  ssh_clear_authorized_keys = true
  ssh_private_key_file      = "${var.SSH_PRIVATE_KEY_FILE}"
  ssh_timeout               = "20m"
  ssh_username              = "ubuntu"
  vm_name                   = "Ubuntu.24.04-${var.image_tag}"
}

build {
  sources = ["source.qemu.ubuntu_24_04"]

  provisioner "ansible" {
    extra_arguments = ["--extra-vars", "ansible_python_interpreter=/usr/bin/python3"]
    playbook_file   = "provisioners/init.yaml"
    use_proxy       = false
    user            = "ubuntu"
  }

  provisioner "ansible" {
    extra_arguments = ["--extra-vars", "ansible_python_interpreter=/usr/bin/python3"]
    pause_before    = "30s"
    playbook_file   = "provisioners/base.yaml"
    use_proxy       = false
    user            = "ubuntu"
  }

  provisioner "shell" {
    script = "provisioners/cleanup.sh"
  }

  post-processor "manifest" {
    output = "manifest.json"
    strip_path = true
    custom_data = {
      "org.openstack.glance.os_distro" = "ubuntu"
      "org.openstack.glance.os_version" = "24.04"
      "org.openstack.glance.os_type" = "linux"
      "org.openstack.glance.architecture" = "x86_64"
      "eu.egi.cloud.description" = "EGI Ubuntu 24.04 image"
    }
  }
}
