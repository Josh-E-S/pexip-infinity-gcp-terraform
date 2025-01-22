# =============================================================================
# Required Variables
# =============================================================================

variable "project_id" {
  description = "The GCP project ID"
  type        = string
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
      source_file = optional(string)  # Required if upload_files = true
      image_name  = string            # Required if upload_files = false
    })
    conferencing = object({
      source_file = optional(string)  # Required if upload_files = true
      image_name  = string            # Required if upload_files = false
    })
  })
}

variable "network_config" {
  description = "Network configuration"
  type = object({
    use_existing_network = bool
    network_name        = string
  })
}

variable "deployment_regions" {
  description = "Region configuration for node deployment"
  type = map(object({
    subnet_name = string
  }))
}

variable "management_access" {
  description = "Management node access configuration"
  type = object({
    enable_ssh          = bool
    enable_provisioning = bool
    cidr_ranges         = list(string)
  })
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

variable "pexip_services" {
  description = "Pexip services configuration"
  type = object({
    enable_sip   = bool
    enable_h323  = bool
    enable_teams = bool
    enable_gmeet = bool
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
