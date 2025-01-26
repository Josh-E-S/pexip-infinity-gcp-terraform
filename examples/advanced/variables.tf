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
  validation {
    condition     = length(var.regions) > 0
    error_message = "At least one region must be specified"
  }
}

variable "management_access" {
  description = "(Required) CIDR ranges for management access (admin UI, SSH, provisioning)"
  type = object({
    cidr_ranges = list(string)
  })
  validation {
    condition     = length(var.management_access.cidr_ranges) > 0
    error_message = "At least one CIDR range must be specified for management access"
  }
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
  validation {
    condition     = var.pexip_images.upload_files ? (var.pexip_images.management.source_file != null && var.pexip_images.conferencing.source_file != null) : true
    error_message = "When upload_files is true, both management.source_file and conferencing.source_file must be provided"
  }
  validation {
    condition     = !var.pexip_images.upload_files ? (var.pexip_images.management.image_name != "" && var.pexip_images.conferencing.image_name != "") : true
    error_message = "When upload_files is false, both management.image_name and conferencing.image_name must be provided"
  }
}

variable "management_node" {
  description = "(Required) Management node configuration"
  type = object({
    name         = string           # Name for the management node
    region       = string           # Must match one of the deployment regions
    public_ip    = bool             # Whether to assign a public IP
    machine_type = optional(string) # (Optional) Defaults to n2-highcpu-4
    disk_size    = optional(number) # (Optional) Boot disk size in GB, defaults to 100
  })
  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.management_node.name))
    error_message = "Name must start with a letter, contain only lowercase letters, numbers, and hyphens, and end with a letter or number"
  }
}

variable "transcoding_nodes" {
  description = "(Required) Transcoding nodes configuration"
  type = object({
    regional_config = map(object({
      count        = number           # Number of nodes in this region
      name         = string           # Name prefix for the nodes
      public_ip    = bool             # Whether to assign public IPs
      machine_type = optional(string) # (Optional) Defaults to n2-highcpu-8
      disk_size    = optional(number) # (Optional) Boot disk size in GB, defaults to 50
    }))
  })
  validation {
    condition = alltrue([for k, v in var.transcoding_nodes.regional_config :
      can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", v.name)) &&
    v.count > 0])
    error_message = "For each region: name must be valid and count must be greater than 0"
  }
}

variable "proxy_nodes" {
  description = "(Optional) Proxy nodes configuration per region. These proxy external call signaling and client connections only."
  type = object({
    regional_config = map(object({
      count        = number           # Number of nodes in this region
      name         = string           # Name prefix for the nodes
      public_ip    = bool             # Whether to assign public IPs
      machine_type = optional(string) # (Optional) Defaults to n2-highcpu-4
      disk_size    = optional(number) # (Optional) Boot disk size in GB, defaults to 50
    }))
  })
  default = {
    regional_config = {}
  }
  validation {
    condition = alltrue([for k, v in var.proxy_nodes.regional_config :
      can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", v.name)) &&
    v.count > 0])
    error_message = "For each region: name must be valid and count must be greater than 0"
  }
}
