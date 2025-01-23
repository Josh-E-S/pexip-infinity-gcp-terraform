# Advanced Pexip Infinity Deployment
# This example demonstrates a full-featured deployment across multiple regions

module "pexip" {
  source = "../../"  # This will be terraform-google-modules/pexip-infinity/google in production

  # Project Configuration
  project_id = var.project_id

  # Multi-region Network Configuration
  regions = [
    {
      region      = "us-central1"    # Primary region
      network     = var.network_name
      subnet_name = var.subnet_names["us-central1"]
    },
    {
      region      = "us-east1"
      network     = var.network_name
      subnet_name = var.subnet_names["us-east1"]
    },
    {
      region      = "europe-west1"
      network     = var.network_name
      subnet_name = var.subnet_names["europe-west1"]
    },
    {
      region      = "asia-southeast1"
      network     = var.network_name
      subnet_name = var.subnet_names["asia-southeast1"]
    }
  ]

  # Management Access Configuration
  management_access = {
    cidr_ranges = var.management_cidrs
  }

  # Service Configuration - Enable all features
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

  # Image Configuration - Using local files
  pexip_images = {
    upload_files = true
    management = {
      source_file = var.management_image_path
      image_name  = "pexip-infinity-management-v30"
    }
    conferencing = {
      source_file = var.conferencing_image_path
      image_name  = "pexip-infinity-conferencing-v30"
    }
  }

  # Management Node Configuration
  management_node = {
    name         = "mgmt-primary"
    region       = "us-central1"
    public_ip    = true
    machine_type = "n2-highcpu-8"    # Upgraded for higher capacity
    disk_size    = 150               # Larger disk for more logs
  }

  # Transcoding Nodes Configuration (2 per region)
  transcoding_nodes = {
    regional_config = {
      "us-central1" = {
        count        = 2
        name         = "transcode-central"
        public_ip    = true
        machine_type = "n2-highcpu-16"  # High capacity for US central
        disk_size    = 80
      }
      "us-east1" = {
        count        = 2
        name         = "transcode-east"
        public_ip    = true
        machine_type = "n2-highcpu-16"
        disk_size    = 80
      }
      "europe-west1" = {
        count        = 2
        name         = "transcode-eu"
        public_ip    = true
        machine_type = "n2-highcpu-16"
        disk_size    = 80
      }
      "asia-southeast1" = {
        count        = 2
        name         = "transcode-asia"
        public_ip    = true
        machine_type = "n2-highcpu-16"
        disk_size    = 80
      }
    }
  }

  # Proxy Nodes Configuration (1 per region)
  proxy_nodes = {
    regional_config = {
      "us-central1" = {
        count        = 1
        name         = "proxy-central"
        public_ip    = true
        machine_type = "n2-highcpu-4"
        disk_size    = 50
      }
      "us-east1" = {
        count        = 1
        name         = "proxy-east"
        public_ip    = true
        machine_type = "n2-highcpu-4"
        disk_size    = 50
      }
      "europe-west1" = {
        count        = 1
        name         = "proxy-eu"
        public_ip    = true
        machine_type = "n2-highcpu-4"
        disk_size    = 50
      }
      "asia-southeast1" = {
        count        = 1
        name         = "proxy-asia"
        public_ip    = true
        machine_type = "n2-highcpu-4"
        disk_size    = 50
      }
    }
  }
}