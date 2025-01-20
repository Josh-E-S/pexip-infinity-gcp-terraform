variable "transcoding_node_name" {
  description = "Base name for transcoding conference node instances"
  type        = string
}

variable "proxy_node_name" {
  description = "Base name for proxy conference node instances"
  type        = string
}

variable "regions" {
  description = "Region configurations with subnet and zone information"
  type = map(object({
    subnet_name = string
    zones       = list(string)
  }))
}

variable "transcoding_node_pools" {
  description = "Configuration for pools of transcoding nodes"
  type = map(object({
    count        = number
    region       = string
    zone         = string
    machine_type = optional(string)
    disk_size    = optional(number)
    disk_type    = optional(string)
    public_ip    = bool
    static_ip    = optional(bool, true)
  }))
}

variable "proxy_node_pools" {
  description = "Configuration for pools of proxy nodes"
  type = map(object({
    count     = number
    region    = string
    zone      = string
    public_ip = bool
    static_ip = optional(bool, true)
  }))
}

variable "transcoding_services" {
  description = "Transcoding node service configuration"
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
    })
  })
}

variable "proxy_services" {
  description = "Proxy node service configuration"
  type = object({
    enable_protocols = object({
      sip    = bool
      h323   = bool
      webrtc = bool
      teams  = bool
      gmeet  = bool
    })
  })
}

variable "network" {
  description = "Network configuration from network module"
  type = object({
    name      = string
    id        = string
    self_link = string
  })
}

variable "conf_image" {
  description = "Conference node image configuration from images module"
  type = object({
    self_link = string
  })
}

variable "ssh_public_key" {
  description = "SSH public key for node access"
  type        = string
  default     = ""
}

variable "management_node" {
  description = "Management node instance reference"
  type = object({
    id = string
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
