# =============================================================================
# Network Module Variables
# =============================================================================

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

# Network Configuration
variable "regions" {
  description = "List of regions with their network and subnet configurations"
  type = list(object({
    region      = string
    network     = string
    subnet_name = string
  }))
}

# Management Access Configuration
variable "management_access" {
  description = "CIDR ranges for all management-related access (admin UI, SSH, provisioning). These ranges will be applied to all management firewall rules. Defaults to 0.0.0.0/0 but should be restricted in production."
  type = object({
    cidr_ranges = list(string)
  })
  default = {
    cidr_ranges = ["0.0.0.0/0"]
  }
}

# Service Configuration
variable "services" {
  description = "Service configuration toggles. All call services (SIP, H.323, Teams, GMeet) are open to 0.0.0.0/0 by default as they handle media and signaling traffic."
  type = object({
    # Management services (inbound)
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
