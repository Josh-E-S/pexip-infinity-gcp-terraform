# =============================================================================
# Network Module Variables
# =============================================================================

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

# Network Configuration
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

# Management Access Configuration
variable "management_access" {
  description = "CIDR ranges for management access (admin UI, SSH, provisioning)"
  type = object({
    cidr_ranges = list(string)
  })
  default = {
    cidr_ranges = ["0.0.0.0/0"]
  }
}

# Service Configuration
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

# =============================================================================
# Dependencies
# =============================================================================

variable "apis" {
  description = "APIs module output"
  type        = any
}
