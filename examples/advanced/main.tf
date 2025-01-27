# =============================================================================
# Advanced Pexip Infinity Deployment Example
# =============================================================================
# This example demonstrates a full-featured deployment across multiple regions
# with proxy nodes and image upload functionality.

terraform {
  required_version = ">= 1.0.0"
}

module "pexip" {
  source  = "Josh-E-S/pexip-infinity/google"
  version = "0.1.3"

  # =============================================================================
  # Required Configuration
  # =============================================================================

  # Project Configuration
  project_id = var.project_id

  # Network Configuration
  regions           = var.regions
  management_access = var.management_access # CIDR ranges for management access

  # Image Configuration - Upload and convert from local files
  pexip_images = var.pexip_images

  # Node Configuration
  management_node   = var.management_node
  transcoding_nodes = var.transcoding_nodes
  proxy_nodes       = var.proxy_nodes

  # =============================================================================
  # Optional Configuration
  # =============================================================================

  # Enable all services for full-featured deployment
  services = var.services
}
