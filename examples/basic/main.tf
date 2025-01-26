# =============================================================================
# Basic Pexip Infinity Deployment Example
# =============================================================================
# This example demonstrates the minimum required configuration for a basic
# single-region deployment with one management node and one transcoding node.

terraform {
  required_version = ">= 1.0.0"
}

module "pexip" {
  source = "../../" # This will be terraform-gcp-modules/pexip-infinity/google in production

  # =============================================================================
  # Required Configuration
  # =============================================================================

  # Project Configuration
  project_id = var.project_id

  # Network Configuration
  regions           = var.regions
  management_access = var.management_access # CIDR ranges for management access

  # Image Configuration - Using existing images
  pexip_images = {
    upload_files = false # Use existing images
    management = {
      image_name = var.pexip_images.management.image_name
    }
    conferencing = {
      image_name = var.pexip_images.conferencing.image_name
    }
  }

  # Node Configuration
  management_node   = var.management_node
  transcoding_nodes = var.transcoding_nodes

  # =============================================================================
  # Optional Configuration
  # =============================================================================

  # The module will use default values for all other optional parameters
  services = var.services
}
