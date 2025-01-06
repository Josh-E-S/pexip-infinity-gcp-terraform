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
  description = "Name of the VPC network"
  type        = string
}

variable "network_routing_mode" {
  description = "The network routing mode (REGIONAL or GLOBAL)"
  type        = string
  default     = "REGIONAL"
  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.network_routing_mode)
    error_message = "network_routing_mode must be either REGIONAL or GLOBAL."
  }
}

variable "auto_generate_subnets" {
  description = "Whether to auto-generate subnets based on CIDR configuration"
  type        = bool
  default     = true
}

variable "network_cidr_base" {
  description = "Base CIDR for auto-generated subnets"
  type        = string
  default     = "10.0.0.0/16"
}

variable "network_subnet_size" {
  description = "Subnet mask size for auto-generated subnets"
  type        = number
  default     = 24
}

variable "network_subnet_start" {
  description = "Starting number for subnet generation"
  type        = number
  default     = 0
}

variable "manual_subnet_cidrs" {
  description = "Manual subnet CIDR configurations (used if auto_generate_subnets = false)"
  type        = map(string)
  default     = {}
}

# =============================================================================
# Management Node Variables
# =============================================================================
variable "mgmt_node" {
  description = "Management node configuration"
  type = object({
    name = optional(string)
    machine_type = string
    disk_size    = number
    disk_type    = optional(string, "pd-standard")
    zone         = string
    region       = string
    public_ip    = bool

    # Network Configuration
    hostname    = string
    domain      = string
    gateway_ip  = string
    subnet_cidr = string

    # Authentication
    admin_username      = string
    admin_password_hash = string  # PBKDF2 with HMAC-SHA256 (Django-style)
    os_password_hash    = string  # SHA-512

    # Optional Services
    enable_error_reporting = optional(bool, false)
    enable_analytics      = optional(bool, false)
    additional_tags       = optional(list(string), [])
  })
}

# =============================================================================
# Conference Node Common Variables
# =============================================================================
variable "conference_node_defaults" {
  description = "Default settings for all conference nodes"
  type = object({
    disk_type = string
    core_service_cidrs = object({
      media    = list(string)
      internal = list(string)
    })
  })
  default = {
    disk_type = "pd-ssd"
    core_service_cidrs = {
      media    = ["0.0.0.0/0"]
      internal = []
    }
  }
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
  description = "Base name for transcoding conference node instances"
  type        = string
  default     = "pexip-transcoding"
}

variable "proxy_node_name" {
  description = "Base name for proxy conference node instances"
  type        = string
  default     = "pexip-proxy"
}

# =============================================================================
# Transcoding Node Variables
# =============================================================================
variable "transcoding_nodes" {
  description = "Transcoding node configurations"
  type = map(object({
    name         = optional(string) # Optional manual name override
    machine_type = string
    disk_size    = number
    disk_type    = optional(string, "pd-standard")
    region       = string
    zone         = string
    public_ip    = bool

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
  }))
}

# =============================================================================
# Proxy Node Variables
# =============================================================================
variable "proxy_nodes" {
  description = "Proxy node configurations"
  type = map(object({
    name         = optional(string) # Optional manual name override
    machine_type = string
    disk_size    = number
    disk_type    = optional(string, "pd-standard")
    region       = string
    zone         = string
    public_ip    = bool

    enable_protocols = object({
      sip    = bool
      h323   = bool
      webrtc = bool
      teams  = bool
      gmeet  = bool
    })

    enable_services = object({
      turn = bool
      rtmp = bool
    })
  }))
}

# =============================================================================
# System Variables
# =============================================================================
variable "system_service_cidrs" {
  description = "CIDR ranges for system services"
  type = object({
    dns = list(string)
    ntp = list(string)
  })
  default = {
    dns = ["8.8.8.8/32", "8.8.4.4/32"]
    ntp = ["0.0.0.0/0"]
  }
}

variable "dns_servers" {
  description = "List of DNS servers"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "ntp_servers" {
  description = "List of NTP servers"
  type        = list(string)
  default     = ["pool.ntp.org"]
}

# =============================================================================
# SSH Configuration
# =============================================================================
variable "ssh_key_path" {
  description = "Path to the SSH public key file for instance access. If not provided, SSH key access will not be configured."
  type        = string
  default     = null
}

variable "ssh_public_key" {
  description = "SSH public key for node access"
  type        = string
  default     = ""
}

# =============================================================================
# Image Variables
# =============================================================================
variable "pexip_version" {
  description = "Version of Pexip Infinity to deploy"
  type        = string
}

variable "mgmt_node_image_path" {
  description = "Local path to the Pexip Infinity Management Node image file"
  type        = string
}

variable "conference_node_image_path" {
  description = "Local path to the Pexip Infinity Conference Node image file"
  type        = string
}

variable "storage_bucket_location" {
  description = "Location for the GCS bucket storing Pexip images"
  type        = string
  default     = "US"
}

variable "environment" {
  description = "Environment name for resource labeling and naming"
  type        = string
  default     = "prod"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "Environment name must contain only lowercase letters, numbers, and hyphens."
  }
}

# =============================================================================
# Port Configurations (for internal use)
# =============================================================================
variable "service_ports" {
  description = "Port configurations for all services"
  type = object({
    core = object({
      sip = object({
        tcp = list(number)
        udp = list(number)
      })
      h323 = object({
        tcp = list(number)
        udp = list(number)
      })
      webrtc = object({
        tcp = list(number)
      })
      media = object({
        udp_range = object({
          start = number
          end   = number
        })
      })
    })
    teams = object({
      tcp = list(number)
      udp_range = object({
        start = number
        end   = number
      })
    })
    turn = object({
      udp = list(number)
    })
    rtmp = object({
      tcp = list(number)
    })
  })
  default = {
    core = {
      sip = {
        tcp = [5060, 5061]
        udp = [5060, 5061]
      }
      h323 = {
        tcp = [1720, 1719]
        udp = [1719]
      }
      webrtc = {
        tcp = [443]
      }
      media = {
        udp_range = {
          start = 40000
          end   = 49999
        }
      }
    }
    teams = {
      tcp = [443, 4477]
      udp_range = {
        start = 50000
        end   = 54999
      }
    }
    turn = {
      udp = [3478]
    }
    rtmp = {
      tcp = [1935]
    }
  }
}

# Authentication Variables
variable "mgmt_node_admin_password_hash" {
  description = "Password hash for management node admin user"
  type        = string
  sensitive   = true
}

variable "mgmt_node_os_password_hash" {
  description = "Password hash for management node OS user"
  type        = string
  sensitive   = true
}
