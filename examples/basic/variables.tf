# =============================================================================
# Project Configuration
# =============================================================================

variable "project_id" {
  description = "(Required) GCP project ID where Pexip Infinity will be deployed"
  type        = string
}

# =============================================================================
# Network Configuration
# =============================================================================

variable "regions" {
  description = "(Required) List of regions and their network configurations. Each region must have an existing VPC network and subnet."
  type = list(object({
    region      = string     # Region name (e.g., us-central1)
    network     = string     # Name of existing VPC network
    subnet_name = string     # Name of existing subnet in the VPC
  }))
  default = [{ region = "us-central1", network = "pexip-infinity", subnet_name = "subnet-1" }] # Set default if needed
}

# =============================================================================
# Image Configuration
# =============================================================================

variable "management_image_name" {
  description = "(Required) Name of the existing Pexip Infinity Management Node image"
  type        = string
}

variable "conferencing_image_name" {
  description = "(Required) Name of the existing Pexip Infinity Conferencing Node image"
  type        = string
}

# =============================================================================
# Node Configuration
# =============================================================================

variable "management_node" {
  description = "(Required) Management node configuration"
  type = object({
    name      = string
    region    = string
    public_ip = bool
  })
  default = { # Set default if needed
    name      = "mgmt-1"
    region    = "us-central1"
    public_ip = true
  }
}

variable "transcoding_nodes" {
  description = "(Optional) Transcoding nodes configuration"
  type = object({
    regional_config = map(object({
      count     = number
      name      = string
      machine_type = string
      public_ip = bool
    }))
  })
  default = { # Set default if needed
    regional_config = {
      "us-central1" = {
        count     = 1
        name      = "transcode"
        machine_type = "n2-standard-2"
        public_ip = true
      }
    }
  }
}