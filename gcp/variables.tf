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

# Protocol Port Configurations
variable "protocol_ports" {
  description = "Port configurations for core protocols"
  type = object({
    sip = object({
      tcp_ports = list(number)
      udp_ports = list(number)
    })
    h323 = object({
      tcp_ports = list(number)
      udp_ports = list(number)
    })
    media = object({
      udp_port_range = object({
        start = number
        end   = number
      })
    })
    webrtc = object({
      tcp_ports = list(number)
      udp_ports = list(number)
    })
  })
  default = {
    sip = {
      tcp_ports = [5060, 5061]
      udp_ports = [5060, 5061]
    }
    h323 = {
      tcp_ports = [1720, 1719]
      udp_ports = [1719]
    }
    media = {
      udp_port_range = {
        start = 40000
        end   = 49999
      }
    }
    webrtc = {
      tcp_ports = [443]
      udp_ports = [40000, 49999] # STUN/TURN ports
    }
  }
}

# Management Node Firewall Rules
variable "mgmt_node_firewall_rules" {
  description = "Firewall rules for management node services"
  type = map(object({
    description = string
    tcp_ports   = list(number)
    udp_ports   = list(number)
    enabled     = bool
  }))
  default = {
    web_admin = {
      description = "Web admin interface"
      tcp_ports   = [443]
      udp_ports   = []
      enabled     = true
    }
    ssh = {
      description = "SSH access"
      tcp_ports   = [22]
      udp_ports   = []
      enabled     = true
    }
    ldap = {
      description = "LDAP authentication"
      tcp_ports   = [389, 636]
      udp_ports   = []
      enabled     = false
    }
    snmp = {
      description = "SNMP monitoring"
      tcp_ports   = []
      udp_ports   = [161]
      enabled     = false
    }
    syslog = {
      description = "Syslog"
      tcp_ports   = [514]
      udp_ports   = [514]
      enabled     = false
    }
    smtp = {
      description = "SMTP email"
      tcp_ports   = [25, 587]
      udp_ports   = []
      enabled     = false
    }
  }
}

# Conference Node Firewall Rules
variable "conference_node_firewall_rules" {
  description = "Firewall rules for conference node services"
  type = map(object({
    description = string
    tcp_ports   = list(number)
    udp_ports   = list(number)
    enabled     = bool
    node_types  = list(string) # ["transcoding"], ["proxy"], or ["transcoding", "proxy"]
  }))
  default = {
    sip = {
      description = "SIP signaling"
      tcp_ports   = [5060, 5061]
      udp_ports   = [5060, 5061]
      enabled     = true
      node_types  = ["transcoding", "proxy"]
    }
    h323 = {
      description = "H.323 signaling"
      tcp_ports   = [1720]
      udp_ports   = [1719]
      enabled     = true
      node_types  = ["transcoding", "proxy"]
    }
    media = {
      description = "Media ports"
      tcp_ports   = []
      udp_ports   = [40000, 49999] # Range will be handled in the firewall rule
      enabled     = true
      node_types  = ["transcoding", "proxy"]
    }
    webrtc = {
      description = "WebRTC"
      tcp_ports   = [443]
      udp_ports   = []
      enabled     = true
      node_types  = ["transcoding", "proxy"]
    }
    one_touch_join = {
      description = "One-Touch Join"
      tcp_ports   = [443]
      udp_ports   = []
      enabled     = false
      node_types  = ["transcoding"]
    }
    teams = {
      description = "Microsoft Teams integration"
      tcp_ports   = [443]
      udp_ports   = []
      enabled     = false
      node_types  = ["transcoding"]
    }
    epic = {
      description = "Epic integration"
      tcp_ports   = [443]
      udp_ports   = []
      enabled     = false
      node_types  = ["transcoding"]
    }
    event_sink = {
      description = "Event Sink"
      tcp_ports   = [443]
      udp_ports   = []
      enabled     = false
      node_types  = ["transcoding"]
    }
    snmp = {
      description = "SNMP monitoring"
      tcp_ports   = []
      udp_ports   = [161]
      enabled     = false
      node_types  = ["transcoding", "proxy"]
    }
    syslog = {
      description = "Syslog"
      tcp_ports   = [514]
      udp_ports   = [514]
      enabled     = false
      node_types  = ["transcoding", "proxy"]
    }
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

# Node Services Configuration
variable "node_services" {
  description = "Configuration for node services including ports, protocols, and which node types they apply to"
  type = map(object({
    description = string
    ports       = list(number)
    protocol    = string
    enabled     = bool
    node_types  = list(string) # Can be ["transcoding"], ["proxy"], or ["transcoding", "proxy"]
  }))

  default = {
    one_touch_join = {
      description = "One-Touch Join service"
      ports       = [443]
      protocol    = "tcp"
      enabled     = false
      node_types  = ["transcoding", "proxy"]
    }
    event_sink = {
      description = "Event Sink service"
      ports       = [80, 443]
      protocol    = "tcp"
      enabled     = false
      node_types  = ["transcoding", "proxy"]
    }
    epic = {
      description = "Epic integration service"
      ports       = [443]
      protocol    = "tcp"
      enabled     = false
      node_types  = ["transcoding"]
    }
    ai_media = {
      description = "AI Media service"
      ports       = [443]
      protocol    = "tcp"
      enabled     = false
      node_types  = ["transcoding"]
    }
    teams = {
      description = "Microsoft Teams integration"
      ports       = [443]
      protocol    = "tcp"
      enabled     = false
      node_types  = ["transcoding"]
    }
    exchange = {
      description = "Exchange integration"
      ports       = [443]
      protocol    = "tcp"
      enabled     = false
      node_types  = ["transcoding"]
    }
    smtp = {
      description = "SMTP service"
      ports       = [587]
      protocol    = "tcp"
      enabled     = false
      node_types  = ["transcoding"]
    }
  }
}

# Shared Services Configuration
variable "shared_services" {
  description = "Enable/disable shared services available to both Management and Conference nodes"
  type = object({
    snmp      = bool
    syslog    = bool
    web_proxy = bool
    ssh       = bool
  })
  default = {
    snmp      = false
    syslog    = true
    web_proxy = false
    ssh       = true
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

# Network Configuration
variable "network_config" {
  description = "Network configuration for the Pexip infrastructure"
  type = object({
    name         = string
    routing_mode = string
  })
  default = {
    name         = "pexip-network"
    routing_mode = "GLOBAL"
  }
}
