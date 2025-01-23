# Required Variables
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "network_name" {
  description = "Name of the existing VPC network"
  type        = string
}

variable "subnet_name" {
  description = "Name of the existing subnet in us-central1"
  type        = string
}

variable "management_image_name" {
  description = "Name of the existing Pexip management node image"
  type        = string
}

variable "conferencing_image_name" {
  description = "Name of the existing Pexip conferencing node image"
  type        = string
}