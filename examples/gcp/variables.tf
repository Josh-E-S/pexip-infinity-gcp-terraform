# Project Variables
variable "project_id" {
  description = "The GCP project ID to deploy to"
  type        = string
}

# Region and Zone Variables
variable "default_region" {
  description = "The default GCP region for resource deployment"
  type        = string
  default     = "us-west1" # Oregon
}

variable "region_2" {
  description = "Optional second region for multi-region deployment"
  type        = string
  default     = "us-central1" # Iowa
}

variable "region_3" {
  description = "Optional third region for multi-region deployment"
  type        = string
  default     = "us-east1" # South Carolina
}

variable "zones" {
  description = "Map of regions to default zones for deployment"
  type        = map(list(string))
  default = {
    "us-west1"    = ["us-west1-a"]
    "us-central1" = ["us-central1-a"]
    "us-east1"    = ["us-east1-b"]
  }
}

# Network Variables
variable "network_name" {
  description = "Name of the VPC network to create"
  type        = string
  default     = "pexip-infinity-network"
}

variable "subnet_cidr_ranges" {
  description = "Map of subnet CIDR ranges per region"
  type        = map(string)
  default = {
    "us-west1"    = "10.0.0.0/20"
    "us-central1" = "10.1.0.0/20"
    "us-east1"    = "10.2.0.0/20"
  }
}

variable "enable_public_ips" {
  description = "Option to enable public IP addresses for nodes"
  type        = bool
  default     = false
}

# Instance Names
variable "mgmt_node_name" {
  description = "Name of the Management Node instance"
  type        = string
  default     = "pexip-mgr"
}

variable "conf_node_name" {
  description = "Prefix for Conference Node instances - will be combined with region and number"
  type        = string
  default     = "pexip-conf"
}

# Management Node Variables
variable "mgmt_machine_type" {
  description = "Machine type for Management Node"
  type        = string
  default     = "n2-highcpu-4"
}

variable "mgmt_node_image" {
  description = "GCP Image name for Management Node"
  type        = string
}

variable "mgmt_node_disk_size" {
  description = "Boot disk size for Management Node in GB"
  type        = number
  default     = 100
}

variable "mgmt_node_disk_type" {
  description = "Boot disk type for Management Node"
  type        = string
  default     = "pd-ssd"
}

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
  description = "PBKDF2 SHA-256 hashed password for web admin interface"
  type        = string
  sensitive   = true
}

variable "mgmt_node_os_password_hash" {
  description = "SHA-512 hashed password for OS admin user"
  type        = string
  sensitive   = true
}

# Conference Node Variables
variable "conf_machine_type" {
  description = "Machine type for Conference Nodes"
  type        = string
  default     = "n2-highcpu-8"
}

variable "conf_node_image" {
  description = "GCP image name for Conference Nodes"
  type        = string
}

variable "conf_node_disk_size" {
  description = "Boot disk size for Conference Nodes in GB"
  type        = number
  default     = 50
}

variable "conf_node_disk_type" {
  description = "Boot disk type for Conference Nodes"
  type        = string
  default     = "pd-ssd"
}

variable "conf_node_count" {
  description = "Number of Conference Nodes to deploy per region"
  type        = map(number)
  default = {
    "us-west1"    = 1
    "us-central1" = 1
  }
}

# SSH Configuration
variable "ssh_public_key" {
  description = "SSH public key for admin user (must have username 'admin')"
  type        = string
}

# Firewall Variables
variable "management_allowed_cidrs" {
  description = "List of CIDR ranges allowed to access Management Node"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "conf_node_allowed_cidrs" {
  description = "List of CIDR ranges allowed to access Conference Nodes"
  type        = list(string)
  default     = ["0.0.0.0/0"]
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
