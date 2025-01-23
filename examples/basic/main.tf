terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
}

# Basic Pexip Infinity deployment
module "pexip" {
  source = "../../"  # Use Josh-E-S/pexip-infinity/google in production
  
  project_id = var.project_id
  
  # Single region deployment
  regions = [{
    region      = "us-west1"
    network     = "pexip-net"
    subnet_name = "pexip-subnet"
  }]

  # Use existing Pexip images
  pexip_images = {
    upload_files = false
    management = {
      image_name = "pexip-infinity-29-mgmt"
    }
    conferencing = {
      image_name = "pexip-infinity-29-conf"
    }
  }

  # Basic management node
  management_node = {
    name      = "mgmt"
    region    = "us-west1"
    public_ip = true
  }

  # Single transcoding node
  transcoding_nodes = {
    regional_config = {
      "us-west1" = {
        name         = "transcode"
        machine_type = "n1-standard-4"
        public_ip    = true
      }
    }
  }
}

# Output connection information
output "connection_info" {
  description = "Connection information for Pexip nodes"
  value       = module.pexip.z_connection_info
}
