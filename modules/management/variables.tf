variable "mgmt_node_name" {
  description = "Base name for the management node instance"
  type        = string
}

variable "mgmt_node" {
  description = "Management node configuration"
  type = object({
    name         = optional(string)
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
}

variable "regions" {
  description = "Region configurations with subnet and zone information"
  type = map(object({
    subnet_name = string
    zones       = list(string)
  }))
}

variable "network" {
  description = "Network configuration from network module"
  type = object({
    name      = string
    id        = string
    self_link = string
  })
}

variable "mgmt_image" {
  description = "Management node image configuration from images module"
  type = object({
    self_link = string
  })
}

variable "ssh_public_key" {
  description = "SSH public key for management node access"
  type        = string
  default     = ""
}

variable "apis" {
  description = "Enabled APIs from the apis module"
  type = object({
    enabled_apis = map(object({
      id = string
    }))
  })
}
