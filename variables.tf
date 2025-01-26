# =============================================================================
# Project Configuration
# =============================================================================

variable "project_id" {
  description = "(Required) GCP project ID where Pexip Infinity will be deployed"
  type        = string
}

variable "regions" {
  description = "(Required) List of regions and their network configurations. Each region must have an existing VPC network and subnet."
  type = list(object({
    region      = string # Region name
    network     = string # Name of existing VPC network
    subnet_name = string # Name of existing subnet in the VPC
  }))
  validation {
    condition     = length(var.regions) > 0
    error_message = "At least one region must be specified"
  }
}

# =============================================================================
# Management Access Configuration
# =============================================================================

variable "management_access" {
  description = "CIDR ranges for management access (admin UI, SSH, provisioning). Must be specified for security purposes."
  type = object({
    cidr_ranges = list(string)
  })

  validation {
    condition     = length(var.management_access.cidr_ranges) > 0
    error_message = "At least one CIDR range must be specified for management access"
  }
}

# =============================================================================
# Image Configuration
# =============================================================================

variable "pexip_images" {
  description = "(Required) Pexip Infinity image configuration. Two options are available:\n  1. Upload and create your own images (set upload_files = true and provide source_file paths and image_names)\n  2. Use existing images (set upload_files = false and provide image_names)"
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

# =============================================================================
# Node Configurations
# =============================================================================

variable "management_node" {
  description = "(Required) Management node configuration. Only one management node can be deployed."
  type = object({
    name         = string           # Name for the management node
    region       = string           # Must match one of the regions specified in var.regions
    public_ip    = optional(bool)   # (Optional) Whether to assign a public IP, defaults to true
    machine_type = optional(string) # (Optional) Defaults to n2-highcpu-4
    disk_size    = optional(number) # (Optional) Boot disk size in GB, defaults to 100
  })
  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.management_node.name))
    error_message = "Name must start with a letter, contain only lowercase letters, numbers, and hyphens, and end with a letter or number"
  }
}

variable "transcoding_nodes" {
  description = "Transcoding nodes configuration per region. These handle media processing. At least one transcoding node is required."
  type = object({
    regional_config = map(object({
      count        = number           # Number of nodes in this region
      name         = string           # Name prefix for the nodes
      public_ip    = optional(bool)   # (Optional) Whether to assign public IPs, defaults to true
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
  description = "(Optional) Proxy nodes configuration per region. These proxy external call signaling and client connections only. If not specified, no proxy nodes will be created."
  type = object({
    regional_config = map(object({
      count        = number           # Number of nodes in this region
      name         = string           # Name prefix for the nodes
      public_ip    = optional(bool)   # (Optional) Whether to assign public IPs, defaults to true
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

# =============================================================================
# Service Configuration
# =============================================================================

variable "services" {
  description = "(Optional) Service configuration toggles. Enable only the services you need."
  type = object({
    # Management services
    enable_ssh               = optional(bool) # (Optional) SSH access to nodes, default: true
    enable_conf_provisioning = optional(bool) # (Optional) Conferencing node provisioning, default: true

    # Call services (inbound)
    enable_sip   = optional(bool) # (Optional) SIP/SIP-TLS calling, default: true
    enable_h323  = optional(bool) # (Optional) H.323 calling, default: true
    enable_teams = optional(bool) # (Optional) Microsoft Teams integration, default: true
    enable_gmeet = optional(bool) # (Optional) Google Meet integration, default: true

    # Optional services
    enable_teams_hub = optional(bool) # (Optional) Teams Connector Azure Event Hub, default: false
    enable_syslog    = optional(bool) # (Optional) External syslog, default: false
    enable_smtp      = optional(bool) # (Optional) Email notifications, default: false
    enable_ldap      = optional(bool) # (Optional) LDAP authentication, default: false
  })
  default = {
    enable_ssh               = true
    enable_conf_provisioning = true
    enable_sip               = true
    enable_h323              = true
    enable_teams             = true
    enable_gmeet             = true
    enable_teams_hub         = false
    enable_syslog            = false
    enable_smtp              = false
    enable_ldap              = false
  }
}
