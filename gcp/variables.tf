# Project Variables
variable "project_id" {
  description = "The GCP project ID to deploy to"
  type        = string
}

# Instance Configuration Maps
variable "instance_configs" {
  description = "Map of predefined instance configurations for different Pexip node types"
  type = map(object({
    machine_type = string
    disk_size    = number
    disk_type    = string
    tags         = list(string)
  }))
  default = {
    management = {
      machine_type = "n2-highcpu-4"
      disk_size    = 100
      disk_type    = "pd-ssd"
      tags         = ["pexip-management"]
    }
    conference_transcoding = {
      machine_type = "n2-highcpu-8"
      disk_size    = 50
      disk_type    = "pd-ssd"
      tags         = ["pexip-conference", "pexip-transcoding"]
    }
    conference_proxy = {
      machine_type = "n2-highcpu-4"
      disk_size    = 50
      disk_type    = "pd-ssd"
      tags         = ["pexip-conference", "pexip-proxy"]
    }
  }
}

# Region Configuration Map
variable "regions" {
  description = "Map of region configurations for Pexip deployment"
  type = map(object({
    priority = number
    cidr     = string
    conference_nodes = object({
      transcoding = object({
        count = number
        zones = list(string)
        config = optional(object({
          machine_type = optional(string)
          disk_size    = optional(number)
        }))
      })
      proxy = optional(object({
        count = number
        zones = list(string)
        config = optional(object({
          machine_type = optional(string)
          disk_size    = optional(number)
        }))
      }))
    })
  }))
  validation {
    condition     = length([for r in var.regions : r if r.priority == 1]) == 1
    error_message = "Exactly one region must be designated as primary (priority = 1)."
  }
}

# Firewall Configuration Map
variable "firewall_rules" {
  description = "Map of firewall rules configurations for different Pexip components"
  type = map(object({
    ports    = list(string)
    protocol = string
    priority = number
    tags     = list(string)
  }))
  default = {
    management = {
      ports    = ["443", "22"]
      protocol = "tcp"
      priority = 1000
      tags     = ["pexip-management"]
    }
    conference_transcoding = {
      ports    = ["443", "1720", "5060", "5061", "33000-39999"]
      protocol = "tcp"
      priority = 1001
      tags     = ["pexip-conference", "pexip-transcoding"]
    }
    conference_transcoding_udp = {
      ports    = ["1719", "33000-39999", "40000-49999"]
      protocol = "udp"
      priority = 1002
      tags     = ["pexip-conference", "pexip-transcoding"]
    }
    conference_proxy = {
      ports    = ["443", "5061", "40000-49999"]
      protocol = "tcp"
      priority = 1003
      tags     = ["pexip-conference", "pexip-proxy"]
    }
    conference_proxy_udp = {
      ports    = ["40000-49999"]
      protocol = "udp"
      priority = 1004
      tags     = ["pexip-conference", "pexip-proxy"]
    }
    internal = {
      ports    = [] # Allow all ports for internal communication
      protocol = "all"
      priority = 900
      tags     = ["pexip-management", "pexip-conference"]
    }
  }
}

# Network Configuration Map
variable "network_config" {
  description = "Network configuration for Pexip deployment"
  type = object({
    name                     = string
    routing_mode             = string
    enable_public_ips        = bool
    management_allowed_cidrs = list(string)
    conference_allowed_cidrs = list(string)
  })
  default = {
    name                     = "pexip-infinity-network"
    routing_mode             = "GLOBAL"
    enable_public_ips        = false
    management_allowed_cidrs = ["0.0.0.0/0"]
    conference_allowed_cidrs = ["0.0.0.0/0"]
  }
}

# Node Names
variable "mgmt_node_name" {
  description = "Name prefix for the Management Node instance"
  type        = string
  default     = "pexip-mgr"
}

variable "conference_node_name" {
  description = "Base name prefix for Conference Node instances"
  type        = string
  default     = "pexip-conf"
}

# Management Node Variables
variable "mgmt_node_hostname" {
  description = "Hostname for Management Node"
  type        = string
  default     = "mgr"
}

variable "mgmt_node_domain" {
  description = "Domain for Management Node"
  type        = string
}

variable "mgmt_node_gateway" {
  description = "Gateway IP for Management Node"
  type        = string
}

variable "mgmt_node_admin_password_hash" {
  description = "Password hash for Management Node admin user"
  type        = string
  sensitive   = true
}

variable "mgmt_node_os_password_hash" {
  description = "Password hash for Management Node OS user"
  type        = string
  sensitive   = true
}

# SSH Configuration
variable "ssh_public_key" {
  description = "SSH public key for admin user (must have username 'admin'). If not provided, a key pair will be generated and the private key will be stored in Secret Manager."
  type        = string
  default     = ""
}

# Pexip Configuration Variables
variable "enable_error_reporting" {
  description = "Enable error reporting to Pexip"
  type        = bool
  default     = false
}

variable "enable_analytics" {
  description = "Enable analytics reporting to Pexip"
  type        = bool
  default     = false
}

variable "dns_servers" {
  description = "List of DNS servers to configure"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "ntp_servers" {
  description = "List of NTP servers to configure"
  type        = list(string)
  default     = ["169.254.169.254"]
}

# Labels and Tags
variable "labels" {
  description = "Map of labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment name for resource labeling"
  type        = string
  default     = "production"
}

# Storage Variables
variable "storage_bucket_location" {
  description = "Location for GCS buckets"
  type        = string
  default     = "US"
}

variable "pexip_images_bucket" {
  description = "Name of the GCS bucket to store Pexip images"
  type        = string
  default     = "pexip-infinity-images"
}

variable "pexip_version" {
  description = "Pexip Infinity version to deploy"
  type        = string
}

variable "pexip_mgr_image_source" {
  description = "Local path to Pexip Management Node tar.gz image file"
  type        = string
}

variable "pexip_conf_image_source" {
  description = "Local path to Pexip Conference Node tar.gz image file"
  type        = string
}

# Protocol Configuration
variable "enable_protocols" {
  description = "Enable/disable core communication protocols"
  type = object({
    h323   = bool
    sip    = bool
    webrtc = bool
  })
  default = {
    h323   = true
    sip    = true
    webrtc = true
  }
}

# Management Node Services Configuration
variable "mgmt_node_services" {
  description = "Enable/disable Management Node services"
  type = object({
    ftp_backup      = bool
    ldap            = bool
    smtp            = bool
    teams_event_hub = bool
    exchange        = bool
    cloud_bursting  = bool
    usage_stats     = bool
  })
  default = {
    ftp_backup      = false
    ldap            = false
    smtp            = true
    teams_event_hub = false
    exchange        = false
    cloud_bursting  = false
    usage_stats     = false
  }
}

# Conference Node Services Configuration
variable "conf_node_services" {
  description = "Enable/disable Conference Node services"
  type = object({
    one_touch_join = bool
    epic           = bool
    ai_media       = bool
    event_sink     = bool
    ad_fs          = bool
  })
  default = {
    one_touch_join = false
    epic           = false
    ai_media       = false
    event_sink     = false
    ad_fs          = false
  }
}

# Shared Services Configuration
variable "shared_services" {
  description = "Enable/disable shared services available to both Management and Conference nodes"
  type = object({
    snmp      = bool
    syslog    = bool
    web_proxy = bool
  })
  default = {
    snmp      = false
    syslog    = true
    web_proxy = false
  }
}

# Service Ports Configuration
variable "service_ports" {
  description = "Custom port configurations for various services"
  type = object({
    smtp      = optional(number, 587)
    syslog    = optional(number, 514)
    web_proxy = optional(number, 8080)
  })
  default = {
    smtp      = 587
    syslog    = 514
    web_proxy = 8080
  }
}

# Service CIDR Configuration
variable "service_cidrs" {
  description = "CIDR ranges for different service types"
  type = object({
    mgmt_services   = list(string)
    conf_services   = list(string)
    shared_services = list(string)
    peripheral      = list(string)
  })
  default = {
    mgmt_services   = ["0.0.0.0/0"]
    conf_services   = ["0.0.0.0/0"]
    shared_services = ["0.0.0.0/0"]
    peripheral      = ["0.0.0.0/0"]
  }
}

# SSH Access Configuration
variable "enable_ssh" {
  description = "Enable SSH access to Management Node"
  type        = bool
  default     = true
}
