# =============================================================================
# Images Module Variables
# =============================================================================

# Required Variables
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "Region for storing images"
  type        = string
}

variable "pexip_version" {
  description = "Pexip Infinity version"
  type        = string
}

# Image Configuration
variable "images" {
  description = "Pexip Infinity image configuration"
  type = object({
    upload_files = bool
    management = object({
      source_file = optional(string) # Required if upload_files = true
      image_name  = string           # Required if upload_files = false
    })
    conferencing = object({
      source_file = optional(string) # Required if upload_files = true
      image_name  = string           # Required if upload_files = false
    })
  })
}

# APIs
variable "apis" {
  description = "APIs module output"
  type        = any
}
