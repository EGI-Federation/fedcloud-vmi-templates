# The provider where the deployment is actually performed
provider "openstack" {
  cloud = "deploy"
}

# Configurable stuff
variable "net_id" {
  type        = string
  description = "The id of the network"
}

variable "flavor_id" {
  type        = string
  description = "VM flavor id"
}

data "openstack_images_image_v2" "ubuntu-24" {
  most_recent = true
  name_regex  = "ubuntu:24.04"
  properties = {
    image_list = "egi_vm_images"
  }
}

resource "openstack_compute_instance_v2" "builder" {
  name            = "builder"
  image_id        = data.openstack_images_image_v2.ubuntu-24.id
  flavor_id       = var.flavor_id
  security_groups = ["default"]
  user_data       = file("cloud-init.yaml")
  network {
    uuid = var.net_id
  }
}

output "instance-id" {
  value = openstack_compute_instance_v2.builder.id
}
