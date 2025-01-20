variable "network_name" {
  description = "Name of the existing VPC network to use"
  type        = string
}

variable "mgmt_node_name" {
  description = "Base name for the management node instance"
  type        = string
}

variable "transcoding_node_name" {
  description = "Base name for transcoding conference node instances"
  type        = string
}

variable "proxy_node_name" {
  description = "Base name for proxy conference node instances"
  type        = string
}

variable "mgmt_node" {
  description = "Management node configuration"
  type = object({
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
}

variable "mgmt_services" {
  description = "Management node service configuration"
  type = object({
    ports = object({
      admin_ui = object({
        tcp = list(string)
      })
    })
  })
}

variable "transcoding_services" {
  description = "Transcoding node service configuration"
  type = object({
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
    enable_services = object({
      one_touch_join = bool
      event_sink     = bool
    })
  })
}

variable "proxy_services" {
  description = "Proxy node service configuration"
  type = object({
    ports = object({
      media = object({
        udp_range = object({
          start = number
          end   = number
        })
      })
    })
  })
}

variable "conferencing_nodes_provisioning" {
  description = "Conferencing nodes provisioning configuration"
  type = object({
    services = object({
      provisioning = bool
    })
    allowed_cidrs = object({
      provisioning = list(string)
    })
  })
}

variable "apis" {
  description = "Enabled APIs from the apis module"
  type = object({
    enabled_apis = map(object({
      id = string
    }))
  })
}
