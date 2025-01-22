# =============================================================================
# Project Configuration
# =============================================================================

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network to use"
  type        = string
}

variable "regions" {
  description = "Map of regions and their subnet configurations"
  type = map(object({
    subnet_name = string
  }))
}

# =============================================================================
# Management Access Configuration
# =============================================================================

variable "management_access" {
  description = "CIDR ranges for management access (admin UI, SSH, provisioning)"
  type = object({
    cidr_ranges = list(string)
  })
  default = {
    cidr_ranges = ["0.0.0.0/0"]
  }
}

# =============================================================================
# Service Configuration
# =============================================================================

variable "services" {
  description = "Service configuration toggles"
  type = object({
    # Management services
    enable_ssh               = bool
    enable_conf_provisioning = bool

    # Call services (inbound)
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

variable "region" {
  description = "Primary region for Pexip deployment"
  type        = string
}

variable "pexip_version" {
  description = "Pexip Infinity version"
  type        = string
}

variable "pexip_images" {
  description = "Pexip Infinity image configuration"
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

variable "management_node" {
  description = "Management node configuration"
  type = object({
    name      = string
    region    = string
    public_ip = bool
  })
}

variable "transcoding_nodes" {
  description = "Transcoding nodes configuration"
  type = object({
    regional_config = map(object({
      count        = number
      public_ip    = bool
      name         = string
      machine_type = string
    }))
  })
}

variable "proxy_nodes" {
  description = "Proxy nodes configuration"
  type = object({
    regional_config = map(object({
      count        = number
      public_ip    = bool
      name         = string
      machine_type = string
    }))
  })
}
