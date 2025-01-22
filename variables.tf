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

variable "deployment_regions" {
  description = "Region configuration for node deployment"
  type = map(object({
    subnet_name = string  # Name of the subnet to use in this region
  }))
}

# =============================================================================
# Management Access Configuration
# =============================================================================

variable "management_access" {
  description = "Management access configuration"
  type = object({
    admin_ranges = list(string)  # For HTTPS (443) and provisioning (8443)
    ssh_ranges   = list(string)  # For SSH (22)
  })
}

# =============================================================================
# Service Configuration
# =============================================================================

variable "pexip_services" {
  description = "Pexip services configuration"
  type = object({
    # Call services (in/out)
    enable_sip   = bool
    enable_h323  = bool
    enable_teams = bool
    enable_gmeet = bool
    
    # Optional outbound services
    enable_teams_hub = optional(bool, false)  # Teams Azure Event Hub
    enable_syslog    = optional(bool, false)  # Syslog
    enable_smtp      = optional(bool, false)  # SMTP
    enable_ldap      = optional(bool, false)  # LDAP/LDAPS
  })
  default = {
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
