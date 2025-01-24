# Basic Pexip Infinity Deployment
# This example shows the minimum required configuration to deploy Pexip Infinity

module "pexip" {
  source = "../../"  # This will be terraform-google-modules/pexip-infinity/google in production

  # Required: Project configuration
  project_id = var.project_id
  
  # Required: Network configuration (single region)
  regions = var.regions

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

  # Required: Management node
  management_node = var.management_node

  # Optional but recommended: Transcoding nodes
  transcoding_nodes = var.transcoding_nodes
}