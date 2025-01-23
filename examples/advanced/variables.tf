variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "management_cidr_ranges" {
  description = "CIDR ranges allowed to access management interfaces"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12"]
}

variable "management_image_path" {
  description = "Path to Pexip management node image file"
  type        = string
}

variable "conferencing_image_path" {
  description = "Path to Pexip conferencing node image file"
  type        = string
}
