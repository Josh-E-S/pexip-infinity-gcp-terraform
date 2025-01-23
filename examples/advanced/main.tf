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

# Advanced Pexip Infinity deployment
module "pexip" {
  source = "../../"  # Use Josh-E-S/pexip-infinity/google in production
  
  project_id = var.project_id
  
  # Multi-region deployment
  regions = [
    {
      region      = "us-west1"
      network     = "pexip-west"
      subnet_name = "pexip-subnet-west"
    },
    {
      region      = "us-east1"
      network     = "pexip-east"
      subnet_name = "pexip-subnet-east"
    }
  ]

  # Restricted management access
  management_access = {
    cidr_ranges = var.management_cidr_ranges
  }

  # Enable all services including optional ones
  services = {
    # Management services
    enable_ssh               = true
    enable_conf_provisioning = true

    # Call services
    enable_sip   = true
    enable_h323  = true
    enable_teams = true
    enable_gmeet = true

    # Optional services
    enable_teams_hub = true
    enable_syslog    = true
    enable_smtp      = true
    enable_ldap      = true
  }

  # Upload custom Pexip images
  pexip_images = {
    upload_files = true
    management = {
      source_file = var.management_image_path
    }
    conferencing = {
      source_file = var.conferencing_image_path
    }
  }

  # Management node in primary region
  management_node = {
    name      = "mgmt-1"
    region    = "us-west1"
    public_ip = true
  }

  # Transcoding nodes in both regions
  transcoding_nodes = {
    regional_config = {
      "us-west1" = {
        name         = "transcode-west"
        machine_type = "n2-standard-8"
        public_ip    = true
      }
      "us-east1" = {
        name         = "transcode-east"
        machine_type = "n2-standard-8"
        public_ip    = true
      }
    }
  }

  # Proxy nodes in both regions
  proxy_nodes = {
    regional_config = {
      "us-west1" = {
        name         = "proxy-west"
        machine_type = "n1-standard-4"
        public_ip    = true
      }
      "us-east1" = {
        name         = "proxy-east"
        machine_type = "n1-standard-4"
        public_ip    = true
      }
    }
  }
}

# Output all details
output "connection_info" {
  description = "Connection information for Pexip nodes"
  value       = module.pexip.z_connection_info
}

output "summary" {
  description = "Summary of deployed resources"
  value       = module.pexip.summary
}
