# =============================================================================
# Required Variables
# =============================================================================

variable "project_id" {
  description = "(Required) GCP project ID where Pexip Infinity will be deployed"
  type        = string
}

variable "regions" {
  description = "(Required) List of regions and their network configurations. Each region must have an existing VPC network and subnet."
  type = list(object({
    region      = string # Region name (e.g., us-central1)
    network     = string # Name of existing VPC network
    subnet_name = string # Name of existing subnet in the VPC
  }))
}

variable "pexip_images" {
  description = "(Required) Configuration for Pexip Infinity images"
  type = object({
    management = object({
      image_name = string # Name of existing management node image
    })
    conferencing = object({
      image_name = string # Name of existing conferencing node image
    })
  })
}

variable "management_access" {
  description = "(Required) CIDR ranges for management access (admin UI, SSH, provisioning)"
  type = object({
    cidr_ranges = list(string)
  })
}

variable "management_node" {
  description = "(Required) Management node configuration"
  type = object({
    name      = string
    region    = string
    public_ip = bool
  })
}

variable "transcoding_nodes" {
  description = "(Optional) Transcoding nodes configuration"
  type = object({
    regional_config = map(object({
      count     = number
      name      = string
      public_ip = bool
    }))
  })
  default = { # Set default if needed
    regional_config = {
      "us-central1" = {
        count     = 1
        name      = "transcode"
        public_ip = true
      }
    }
  }
}
