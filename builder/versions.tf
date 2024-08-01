# This is where the info about the deployment is to be stored
terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.48"
    }
  }
  required_version = ">= 0.13"
}
