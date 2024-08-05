# The provider where the deployment is actually performed
provider "openstack" {
  cloud = "deploy"
}

# Configurable stuff
variable "net_id" {
  type        = string
  description = "The id of the network"
}

variable "image_id" {
  type        = string
  description = "VM image id"
}

variable "flavor_id" {
  type        = string
  description = "VM flavor id"
}


resource "openstack_compute_instance_v2" "builder" {
  name            = "builder"
  image_id        = var.image_id
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
