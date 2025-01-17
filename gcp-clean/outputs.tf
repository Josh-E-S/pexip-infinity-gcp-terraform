# =============================================================================
# Validation Results
# =============================================================================

output "infrastructure_info" {
  description = "Infrastructure deployment information"
  value = {
    network = {
      name = var.network_name
      regions = {
        for region, config in var.regions : region => {
          subnet_name = config.subnet_name
          zones       = config.zones
        }
      }
    }
    nodes = {
      management = {
        region = var.mgmt_node.region
        zone   = var.mgmt_node.zone
      }
      transcoding = {
        count   = length(local.transcoding_nodes)
        regions = distinct([for name, node in local.transcoding_nodes : node.region])
      }
      proxy = {
        count   = length(local.proxy_nodes)
        regions = distinct([for name, node in local.proxy_nodes : node.region])
      }
    }
    machine_types = {
      management  = google_compute_instance.management_node.machine_type
      transcoding = distinct([for name, node in local.transcoding_nodes : google_compute_instance.transcoding_nodes[name].machine_type])
      proxy       = distinct([for name, node in local.proxy_nodes : google_compute_instance.proxy_nodes[name].machine_type])
    }
  }
}

# Management Node Outputs
output "management_node" {
  description = "Management node details"
  value = {
    name         = google_compute_instance.management_node.name
    internal_ip  = google_compute_instance.management_node.network_interface[0].network_ip
    external_ip  = try(google_compute_instance.management_node.network_interface[0].access_config[0].nat_ip, null)
    machine_type = google_compute_instance.management_node.machine_type
    zone         = google_compute_instance.management_node.zone
    region       = var.mgmt_node.region
    hostname     = var.mgmt_node.hostname
    domain       = var.mgmt_node.domain
  }
}

# Conference Node Outputs
output "transcoding_nodes" {
  description = "Transcoding conference node details"
  value = {
    for name, instance in google_compute_instance.transcoding_nodes : name => {
      name         = instance.name
      internal_ip  = instance.network_interface[0].network_ip
      external_ip  = try(instance.network_interface[0].access_config[0].nat_ip, null)
      machine_type = instance.machine_type
      zone         = instance.zone
      region       = local.transcoding_nodes[name].region
      disk_size    = local.transcoding_nodes[name].disk_size
      disk_type    = local.transcoding_nodes[name].disk_type
      public_ip    = local.transcoding_nodes[name].public_ip
      static_ip    = local.transcoding_nodes[name].static_ip
    }
  }
}

output "proxy_nodes" {
  description = "Proxy conference node details"
  value = {
    for name, instance in google_compute_instance.proxy_nodes : name => {
      name         = instance.name
      internal_ip  = instance.network_interface[0].network_ip
      external_ip  = try(instance.network_interface[0].access_config[0].nat_ip, null)
      machine_type = instance.machine_type
      zone         = instance.zone
      region       = local.proxy_nodes[name].region
      public_ip    = local.proxy_nodes[name].public_ip
      static_ip    = local.proxy_nodes[name].static_ip
    }
  }
}

# Network Outputs
output "network_details" {
  description = "Network configuration details"
  value = {
    network_name = data.google_compute_network.network.name
    network_id   = data.google_compute_network.network.id
    subnets = {
      for region, config in var.regions : region => {
        name = config.subnet_name
      }
    }
    firewall_rules = {
      management = {
        admin_ui = google_compute_firewall.mgmt_admin.name
        ssh      = google_compute_firewall.mgmt_ssh.name
        services = google_compute_firewall.mgmt_services.name
      }
      conferencing = {
        transcoding = {
          media    = google_compute_firewall.transcoding_media.name
          services = try(google_compute_firewall.transcoding_services[0].name, null)
        }
        proxy = {
          media = google_compute_firewall.proxy_media.name
        }
        signaling = google_compute_firewall.signaling.name
        internal  = google_compute_firewall.internal.name
      }
    }
  }
}

# Summary Output
output "deployment_summary" {
  description = "Summary of the Pexip Infinity deployment"
  value = {
    project_id    = var.project_id
    pexip_version = var.pexip_version

    nodes = {
      management = {
        count         = 1
        public_access = var.mgmt_node.public_ip
      }
      transcoding = {
        count   = length(local.transcoding_nodes)
        regions = distinct([for name, node in local.transcoding_nodes : node.region])
      }
      proxy = {
        count   = length(local.proxy_nodes)
        regions = distinct([for name, node in local.proxy_nodes : node.region])
      }
    }
  }
}

# Connection Information
output "connection_info" {
  description = "Connection information for Pexip Infinity"
  value = {
    admin_interface = format(
      "https://%s",
      coalesce(
        try(google_compute_instance.management_node.network_interface[0].access_config[0].nat_ip, null),
        google_compute_instance.management_node.network_interface[0].network_ip
      )
    )
    ssh_command = format(
      "ssh admin@%s",
      coalesce(
        try(google_compute_instance.management_node.network_interface[0].access_config[0].nat_ip, null),
        google_compute_instance.management_node.network_interface[0].network_ip
      )
    )
  }

  sensitive = true
}

# Storage Outputs
output "storage_bucket" {
  description = "Details of the storage bucket"
  value = {
    name     = google_storage_bucket.pexip_images.name
    location = google_storage_bucket.pexip_images.location
    url      = google_storage_bucket.pexip_images.url
  }
}

# SSH Key Outputs
output "ssh_key_secret" {
  description = "Name of the Secret Manager secret containing the SSH private key"
  value       = google_secret_manager_secret.ssh_private_key.name
  sensitive   = true
}

# Image Outputs
output "images" {
  description = "Pexip Infinity image details"
  value = {
    storage_bucket = google_storage_bucket.pexip_images.name
    management = {
      name    = google_compute_image.mgmt_image.name
      self_link = google_compute_image.mgmt_image.self_link
    }
    conference = {
      name    = google_compute_image.conf_image.name
      self_link = google_compute_image.conf_image.self_link
    }
  }
}
