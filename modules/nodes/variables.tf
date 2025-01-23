# =============================================================================
# Node Module Variables
# =============================================================================

# Required Variables
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "type" {
  description = "Type of node to create (management, transcoding, proxy)"
  type        = string
  validation {
    condition     = contains(["management", "transcoding", "proxy"], var.type)
    error_message = "Type must be one of: management, transcoding, proxy"
  }
}

variable "name" {
  description = "Name for the node (or prefix if quantity > 1)"
  type        = string
}

variable "region" {
  description = "Region to deploy the node in"
  type        = string
}

variable "network_id" {
  description = "ID of the VPC network to deploy into"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet to deploy into"
  type        = string
}

variable "image_name" {
  description = "Name of the Pexip image to use"
  type        = string
}

# Optional Variables
variable "quantity" {
  description = "Number of nodes to create (only valid for conferencing nodes)"
  type        = number
  default     = 1
  validation {
    condition     = var.type == "management" ? var.quantity == 1 : var.quantity > 0
    error_message = "Quantity must be 1 for management nodes and greater than 0 for conferencing nodes"
  }
}

variable "machine_type" {
  description = "GCP machine type"
  type        = string
  default     = null # Will be set based on node type in locals
}

variable "boot_disk_size" {
  description = "Size of the boot disk in GB"
  type        = number
  default     = null # Will be set based on node type in locals
}

variable "public_ip" {
  description = "Whether to assign a public IP to the node"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels to apply to the node"
  type        = map(string)
  default     = {}
}

variable "apis" {
  description = "Enabled APIs from the apis module"
  type        = any
}
