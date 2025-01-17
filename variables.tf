# =============================================================================
# Project Variables
# =============================================================================
variable "project_id" {
  description = "The GCP project ID to deploy to"
  type        = string
}

# =============================================================================
# Network Variables
# =============================================================================
variable "network_name" {
  description = "Name of the existing VPC network to use"
  type        = string
}

# =============================================================================
# Region Configuration
# =============================================================================
variable "regions" {
  description = "Region configurations with subnet and zone information"
  type = map(object({
    subnet_name = string
    zones       = list(string)
  }))
}

# =============================================================================
# Node Naming Variables
# =============================================================================
variable "mgmt_node_name" {
  description = "Base name for the management node instance"
  type        = string
  default     = "pexip-mgmt"
}

variable "transcoding_node_name" {
  description = "Base name for transcoding conference node instances. Will be used as prefix for all transcoding nodes."
  type        = string
  default     = "pexip-transcoding"
}

variable "proxy_node_name" {
  description = "Base name for proxy conference node instances. Will be used as prefix for all proxy nodes."
  type        = string
  default     = "pexip-proxy"
}

# =============================================================================
# Management Node Configuration
# =============================================================================
variable "mgmt_node" {
  description = "Management node configuration"
  type = object({
    zone         = string
    region       = string
    machine_type = string
    disk_size    = number
    disk_type    = optional(string, "pd-standard")
    public_ip    = bool
    static_ip    = optional(bool, true)
    services = object({
      ssh       = bool
      directory = bool
      smtp      = bool
      syslog    = bool
    })
    allowed_cidrs = object({
      admin_ui = list(string)
      ssh      = list(string)
    })
    service_cidrs = object({
      directory = list(string)
      smtp      = list(string)
      syslog    = list(string)
    })
  })

  validation {
    condition = alltrue([
      for cidr in var.mgmt_node.allowed_cidrs.admin_ui : can(cidrhost(cidr, 0))
    ])
    error_message = "Management node admin_ui CIDR ranges must be valid (e.g., '0.0.0.0/0' or '10.0.0.0/24')"
  }

  validation {
    condition = alltrue([
      for cidr in var.mgmt_node.allowed_cidrs.ssh : can(cidrhost(cidr, 0))
    ])
    error_message = "Management node SSH CIDR ranges must be valid (e.g., '0.0.0.0/0' or '10.0.0.0/24')"
  }

  validation {
    condition = alltrue(flatten([
      [for cidr in var.mgmt_node.service_cidrs.directory : can(cidrhost(cidr, 0))],
      [for cidr in var.mgmt_node.service_cidrs.smtp : can(cidrhost(cidr, 0))],
      [for cidr in var.mgmt_node.service_cidrs.syslog : can(cidrhost(cidr, 0))]
    ]))
    error_message = "Management node service CIDR ranges must be valid (e.g., '0.0.0.0/0' or '10.0.0.0/24')"
  }
}

# =============================================================================
# Node Pool Variables
# =============================================================================
variable "transcoding_node_pools" {
  description = "Transcoding node pool configurations. Machine type can vary between pools."
  type = map(object({
    machine_type = string
    disk_size    = number
    disk_type    = optional(string, "pd-standard")
    region       = string
    zone         = string
    count        = number
    public_ip    = bool
    static_ip    = optional(bool, true)
  }))
}

variable "proxy_node_pools" {
  description = "Proxy node pool configurations. All pools use n2-standard-4."
  type = map(object({
    region    = string
    zone      = string
    count     = number
    public_ip = bool
    static_ip = optional(bool, true)
  }))
}

# =============================================================================
# Service Configuration Per Node Type
# =============================================================================
variable "mgmt_services" {
  description = "Management node service configuration"
  type = object({
    enable_services = object({
      admin_ui  = bool
      directory = bool
      smtp      = bool
      syslog    = bool
    })
    ports = object({
      admin_ui = object({
        tcp = list(string)
      })
      directory = object({
        tcp = list(string)
      })
      smtp = object({
        tcp = list(string)
      })
      syslog = object({
        tcp = list(string)
        udp = list(string)
      })
    })
  })
  default = {
    enable_services = {
      admin_ui  = true
      directory = true
      smtp      = true
      syslog    = true
    }
    ports = {
      admin_ui = {
        tcp = ["443"]
      }
      directory = {
        tcp = ["389", "636"]
      }
      smtp = {
        tcp = ["25", "587"]
      }
      syslog = {
        tcp = ["514"]
        udp = ["514"]
      }
    }
  }
}

variable "transcoding_services" {
  description = "Transcoding nodes service configuration"
  type = object({
    enable_protocols = object({
      sip    = bool
      h323   = bool
      webrtc = bool
      teams  = bool
      gmeet  = bool
    })
    enable_services = object({
      one_touch_join = bool
      event_sink     = bool
      epic           = bool
      captions       = bool
    })
    ports = object({
      media = object({
        udp_range = object({
          start = number
          end   = number
        })
      })
      signaling = object({
        sip_tcp  = list(string)
        sip_udp  = list(string)
        h323_tcp = list(string)
        h323_udp = list(string)
        webrtc   = list(string)
      })
      services = object({
        one_touch_join = list(string)
        event_sink     = list(string)
      })
    })
  })
  default = {
    enable_protocols = {
      sip    = true
      h323   = true
      webrtc = true
      teams  = true
      gmeet  = true
    }
    enable_services = {
      one_touch_join = false
      event_sink     = false
      epic           = false
      captions       = false
    }
    ports = {
      media = {
        udp_range = {
          start = 40000
          end   = 49999
        }
      }
      signaling = {
        sip_tcp  = ["5060", "5061"]
        sip_udp  = ["5060"]
        h323_tcp = ["1720"]
        h323_udp = ["1719"]
        webrtc   = ["443"]
      }
      services = {
        one_touch_join = ["443"]
        event_sink     = ["443"]
      }
    }
  }
}

variable "proxy_services" {
  description = "Proxy nodes service configuration"
  type = object({
    enable_protocols = object({
      sip    = bool
      h323   = bool
      webrtc = bool
      teams  = bool
      gmeet  = bool
    })
    ports = object({
      media = object({
        udp_range = object({
          start = number
          end   = number
        })
      })
      signaling = object({
        sip_tcp  = list(string)
        sip_udp  = list(string)
        h323_tcp = list(string)
        h323_udp = list(string)
        webrtc   = list(string)
      })
    })
  })
  default = {
    enable_protocols = {
      sip    = true
      h323   = true
      webrtc = true
      teams  = true
      gmeet  = true
    }
    ports = {
      media = {
        udp_range = {
          start = 50000
          end   = 54999
        }
      }
      signaling = {
        sip_tcp  = ["5060", "5061"]
        sip_udp  = ["5060"]
        h323_tcp = ["1720"]
        h323_udp = ["1719"]
        webrtc   = ["443"]
      }
    }
  }
}

variable "conferencing_nodes_provisioning" {
  description = "Conferencing nodes shared provisioning configuration"
  type = object({
    services = object({
      ssh          = bool
      provisioning = bool
    })
    allowed_cidrs = object({
      provisioning = list(string)
    })
  })

  validation {
    condition = alltrue([
      for cidr in var.conferencing_nodes_provisioning.allowed_cidrs.provisioning : can(cidrhost(cidr, 0))
    ])
    error_message = "Conferencing nodes provisioning CIDR ranges must be valid (e.g., '0.0.0.0/0' or '10.0.0.0/24')"
  }
}

# =============================================================================
# Pexip Images Configuration
# =============================================================================
variable "pexip_version" {
  description = "Version of Pexip Infinity to deploy"
  type        = string
}

variable "pexip_images" {
  description = "Pexip Infinity image configurations. Set upload_files=true to upload and create images, or false to use existing images"
  type = object({
    upload_files = bool
    management = object({
      source_file = optional(string)
      image_name  = string
    })
    conference = object({
      source_file = optional(string)
      image_name  = string
    })
  })

  validation {
    condition = (
      !var.pexip_images.upload_files ||
      (var.pexip_images.management.source_file != null && var.pexip_images.conference.source_file != null)
    )
    error_message = "When upload_files is true, both management.source_file and conference.source_file must be specified"
  }
}
