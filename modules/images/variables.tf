variable "project_id" {
  description = "The GCP project ID to deploy to"
  type        = string
}

variable "regions" {
  description = "Region configurations with subnet and zone information"
  type = map(object({
    subnet_name = string
    zones       = list(string)
  }))
}

variable "pexip_version" {
  description = "Version of Pexip Infinity to deploy"
  type        = string
}

variable "pexip_images" {
  description = "Pexip Infinity image configurations"
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
}

variable "apis" {
  description = "Enabled APIs from the apis module"
  type = object({
    enabled_apis = map(object({
      id = string
    }))
  })
}
