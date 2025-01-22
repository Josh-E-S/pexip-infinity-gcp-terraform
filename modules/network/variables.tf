# =============================================================================
# Network Module Variables
# =============================================================================

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "network_name" {
  description = "Name of existing VPC network"
  type        = string
}

variable "use_existing" {
  description = "Whether to use an existing network"
  type        = bool
}

variable "regions" {
  description = "Map of regions to subnet configurations"
  type = map(object({
    subnet_name = string
  }))
}

# =============================================================================
# Security Configuration
# =============================================================================

variable "management_access" {
  description = "Management node access configuration"
  type = object({
    enable_ssh          = bool
    enable_provisioning = bool
    cidr_ranges         = list(string)
  })
  default = {
    enable_ssh          = true
    enable_provisioning = true
    cidr_ranges         = ["0.0.0.0/0"]
  }
}

variable "services" {
  description = "Service configuration"
  type = object({
    enable_sip   = bool
    enable_h323  = bool
    enable_teams = bool
    enable_gmeet = bool
  })
  default = {
    enable_sip   = true
    enable_h323  = true
    enable_teams = true
    enable_gmeet = true
  }
}

variable "service_ranges" {
  description = "CIDR ranges for service access"
  type = object({
    dns    = list(string)
    ntp    = list(string)
    syslog = list(string)
    smtp   = list(string)
    ldap   = list(string)
  })
  default = {
    dns    = ["0.0.0.0/0"]
    ntp    = ["0.0.0.0/0"]
    syslog = ["0.0.0.0/0"]
    smtp   = ["0.0.0.0/0"]
    ldap   = ["0.0.0.0/0"]
  }
}

# =============================================================================
# Dependencies
# =============================================================================

variable "apis" {
  description = "APIs module output"
  type        = any
}
