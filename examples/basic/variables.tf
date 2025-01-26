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
    upload_files = bool
    management = object({
      source_file = optional(string) # Required if upload_files = true
      image_name  = string           # Required if upload_files = false
    })
    conferencing = object({
      source_file = optional(string) # Required if upload_files = true
      image_name  = string           # Required if upload_files = false
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
  description = "(Required) Transcoding nodes configuration"
  type = object({
    regional_config = map(object({
      count     = number
      name      = string
      public_ip = bool
    }))
  })
}

variable "services" {
  description = "(Optional) Service configuration toggles for firewall rules"
  type = object({
    # Management services
    enable_ssh               = bool
    enable_conf_provisioning = bool

    # Call services
    enable_sip   = bool
    enable_h323  = bool
    enable_teams = bool
    enable_gmeet = bool

    # Optional services
    enable_teams_hub = bool
    enable_syslog    = bool
    enable_smtp      = bool
    enable_ldap      = bool
  })
  default = {
    # Management services default to enabled
    enable_ssh               = true
    enable_conf_provisioning = true

    # Call services default to enabled
    enable_sip   = true
    enable_h323  = true
    enable_teams = true
    enable_gmeet = true

    # Optional services default to disabled
    enable_teams_hub = false
    enable_syslog    = false
    enable_smtp      = false
    enable_ldap      = false
  }
}
