# =============================================================================
# Advanced Pexip Infinity Deployment Example
# =============================================================================
# This example demonstrates a full-featured deployment across multiple regions

terraform {
  required_version = ">= 1.0.0"
}

# =============================================================================
# Main Configuration
# =============================================================================
module "pexip" {
  source = "../../" # This will be terraform-google-modules/pexip-infinity/google in production

  # =============================================================================
  # Project Configuration
  # =============================================================================
  project_id = var.project_id

  # =============================================================================
  # Multi-region Network Configuration
  # =============================================================================
  regions = var.regions

  # =============================================================================
  # Management Access Configuration
  # =============================================================================
  management_access = var.management_access

  # =============================================================================
  # Service Configuration
  # =============================================================================
  services = var.services

  # =============================================================================
  # Image Configuration
  # =============================================================================
  pexip_images = var.pexip_images

  # =============================================================================
  # Node Configurations
  # =============================================================================
  management_node   = var.management_node
  transcoding_nodes = var.transcoding_nodes
  proxy_nodes       = var.proxy_nodes
}
