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
  type = string
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
  iso_checksum              = "sha256:113521ec7f28aa4ab71ba4e5896719da69a0cc46cf341c4ebbd215877214f661"
  iso_url                   = "https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9.6-x86_64-boot.iso"
  memory                    = 1024
  qemuargs                  = [["-cpu", "host"]]
  shutdown_command          = "shutdown -h now"
  ssh_private_key_file      = "${var.SSH_PRIVATE_KEY_FILE}"
  ssh_timeout               = "20m"
  ssh_username              = "root"
  vm_name                   = "alma.9-${var.image_tag}"
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

  post-processor "manifest" {
    output = "manifest.json"
    strip_path = true
    custom_data = {
      "org.openstack.glance.os_distro" = "alma"
      "org.openstack.glance.os_admin_user" = "almalinux"
      "org.openstack.glance.os_version" = "9"
      "org.openstack.glance.os_type" = "linux"
      "org.openstack.glance.architecture" = "x86_64"
      "eu.egi.cloud.image.title" = "EGI Alma 9 image"
    }
  }
}
