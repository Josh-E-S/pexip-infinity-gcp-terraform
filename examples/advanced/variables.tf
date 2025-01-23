# Project Configuration
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

# Network Configuration
variable "network_name" {
  description = "Name of the existing VPC network"
  type        = string
}

variable "subnet_names" {
  description = "Map of region names to subnet names"
  type        = map(string)
}

# Security Configuration
variable "management_cidrs" {
  description = "List of CIDR ranges allowed to access management interfaces"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Replace with actual management IPs in production
}

# Image Configuration
variable "management_image_path" {
  description = "Local path to the Pexip management node image file"
  type        = string
}

variable "conferencing_image_path" {
  description = "Local path to the Pexip conferencing node image file"
  type        = string
}