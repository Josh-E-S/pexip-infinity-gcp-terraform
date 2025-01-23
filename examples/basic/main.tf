# Basic Pexip Infinity Deployment
# This example shows the minimum required configuration to deploy Pexip Infinity

module "pexip" {
  source = "../../"  # This will be terraform-google-modules/pexip-infinity/google in production

  # Required: Project configuration
  project_id = var.project_id
  
  # Required: Network configuration (single region)
  regions = [{
    region      = "us-central1"
    network     = var.network_name     # Must exist
    subnet_name = var.subnet_name      # Must exist
  }]

  # Required: Image configuration (using existing images)
  pexip_images = {
    upload_files = false
    management = {
      image_name = var.management_image_name
    }
    conferencing = {
      image_name = var.conferencing_image_name
    }
  }

  # Required: Management node configuration
  management_node = {
    name   = "mgmt-1"
    region = "us-central1"
  }

  # Optional but recommended: Transcoding nodes
  transcoding_nodes = {
    regional_config = {
      "us-central1" = {
        count = 2
        name  = "transcode"
      }
    }
  }
}